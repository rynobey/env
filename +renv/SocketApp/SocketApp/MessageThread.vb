Imports System.Reflection
Imports System.IO
Imports System.Xml.Serialization
Imports System.Threading

Public Class MessageThread

    Private Controller As Controller
    Private Server As SocketServer
    Private Clients As Queue
    Private Thread As System.Threading.Thread
    Private IsStarted As Boolean = False
    Private IsProcessing As Boolean = False
    Private lockObj As New Object()
    Private Data As New System.Text.StringBuilder()
    Private ReceivedXML As String = ""
    Public Stream As System.Net.Sockets.NetworkStream

    Public Sub New(ByRef Controller As Controller, ByRef Server As SocketServer)
        Me.Controller = Controller
        Me.Server = Server
        Me.Clients = New Queue
        System.Console.WriteLine("Message Thread Created!")
        Me.Thread = New Threading.Thread(AddressOf Me.ProcessLoop)
    End Sub

    Public Sub Enqueue(ByVal Client As System.Net.Sockets.TcpClient)
        Me.Clients.Enqueue(Client)
        If Me.isStarted And Not Me.IsBusy() Then
            Monitor.Enter(Me.lockObj)
            Monitor.Pulse(Me.lockObj)
            Monitor.Exit(Me.lockObj)
        ElseIf Not Me.isStarted Then
            Me.Start()
        End If
    End Sub

    Public Sub Start()
        Me.thread.Start()
        While Not Me.isStarted
            System.Threading.Thread.Sleep(100)
        End While
    End Sub

    Public Function IsBusy()
        Return Me.isProcessing
    End Function

    Public Sub Suspend()
        Me.IsProcessing = False
        Monitor.Enter(Me.lockObj)
        Me.IsProcessing = Monitor.Wait(Me.lockObj)
        Monitor.Exit(Me.lockObj)
    End Sub

    Private Sub Init()
        'Me.WriteLine("Connected.")
    End Sub

    Public Sub ProcessLoop()
        Do
            If Me.isStarted = False Then
                Me.isProcessing = True
                Me.isStarted = True
            End If
            Me.Init()
            Dim Client As System.Net.Sockets.TcpClient = Me.Clients.Dequeue()
            'Try
            Me.HandleClient(Client)
            'Catch ex As Exception
            'System.Console.WriteLine(ex.Message)
            'End Try
            If Me.Clients.Count = 0 Then
                Me.Suspend()
            End If
        Loop
    End Sub

    Private Sub HandleClient(ByRef Client As System.Net.Sockets.TcpClient)
        Me.Stream = Client.GetStream()
        Dim ReceivedXML As String = ""
        Dim pauseCount As Integer = 0
        'Dim msg As Message
        System.Console.WriteLine("Connection Attempt From: " & Me.Server.GetClientIP(Me.Stream))
        If Me.Controller.Authenticate() Then
            Client.LingerState.Enabled = True
            If Client.Connected Then
                Console.WriteLine("Client Connected!!!!!")
                For Each worker In Me.Controller.WorkerThreads
                    worker.Value.msgThread = Me
                Next
            End If
            While Client.Connected
                While Me.Stream.DataAvailable
                    Dim bytes(Client.ReceiveBufferSize - 1) As Byte
                    Dim Len = Me.Stream.Read(bytes, 0, Client.ReceiveBufferSize)
                    If Len > 0 Then
                        Me.Data.Append(System.Text.Encoding.UTF8.GetString(bytes, 0, Len))
                        'Console.WriteLine(System.Text.Encoding.UTF8.GetString(bytes, 0, Len))
                    End If
                End While
                If Me.TxComplete() Then
                    'Try
                    Me.ReceivedXML = Me.ExtractTx()
                    Dim extractedMsg As Message = Me.ExtractMsg()
                    While Not (extractedMsg Is Nothing)
                        If Not Me.Controller.HandleMsg(Me, extractedMsg) Then
                            extractedMsg.Success = 0
                            extractedMsg.Msg = "Unable to process request"
                            extractedMsg.Send(Me.Stream)
                        End If
                        extractedMsg = Me.ExtractMsg()
                    End While
                    'Catch ex As Exception
                    'msg = New Message()
                    'msg.Success = 0
                    'msg.Msg = "Incomplete Transmission"
                    'msg.Send(Me.Stream)
                    'End Try
                Else
                    System.Threading.Thread.Sleep(5)
                    pauseCount = pauseCount + 1
                    ''Send message to test connectivity
                    If pauseCount > 200 Then
                        Try
                            Dim Bytes() As Byte = System.Text.Encoding.UTF8.GetBytes(ControlChars.NullChar)
                            Me.WriteBytes(Bytes, Stream)
                        Catch ex As Exception

                        End Try
                        pauseCount = 0
                    End If
                End If
            End While
        End If
        Console.WriteLine("Client disconnected!!!!!!!")
        For Each worker In Me.Controller.WorkerThreads
            worker.Value.msgThread = Nothing
        Next
        Stream.Close()
        Stream.Dispose()
        Client.Close()
    End Sub

    Private Function ExtractTx()
        Dim extracted As String
        'Try
        Dim DataStr As String = Me.Data.ToString().Trim()
        'Console.WriteLine("TOTAL: " & DataStr)
        Dim startIndex As Integer = DataStr.IndexOf("<Tx>") + 4
        Dim endIndex As Integer = DataStr.IndexOf("</Tx>")
        Dim length As Integer = DataStr.Length
        Dim leftOver As String = ""
        extracted = DataStr.Substring(startIndex, (endIndex) - startIndex)
        'Console.WriteLine("EXTRACTED: " & extracted)
        If endIndex > 0 And endIndex + 5 < length Then
            leftOver = DataStr.Substring(endIndex + 5, length - (endIndex + 5))
        End If
        'Console.WriteLine("REST: " & leftOver)
        Me.Data = New System.Text.StringBuilder(leftOver)
        'Catch ex As Exception
        '    extracted = ""
        'End Try
        Return extracted
    End Function

    Private Function ExtractMsg() As Message
        Dim extracted As Message = Nothing
        If Me.ReceivedXML.Contains("<Message>") And Me.ReceivedXML.Contains("</Message>") Then
            Try
                Dim extractedXML As String = Me.GetExtractedXML(Me.ReceivedXML)
                If extractedXML Is Nothing Then
                    extracted = Nothing
                Else
                    extracted = New Message(extractedXML)
                End If
            Catch ex As Exception
                extracted = Nothing
            End Try
        End If
        Return extracted
    End Function

    Private Function GetExtractedXML(ByVal ReceivedXML As String) As String
        Dim numTries As Integer = 0
        Dim maxTries As Integer = 5
        Dim leftOver As String = ""
        Dim startIndex As Integer = Me.ReceivedXML.IndexOf("<Message>")
        Dim endIndex As Integer = Me.ReceivedXML.IndexOf("</Message>")
        Dim length As Integer = Me.ReceivedXML.Length
        Dim extractedXML As String = Me.ReceivedXML.Substring(startIndex, endIndex + 10)
        Dim numTestsPassed As Integer = 0
        While numTestsPassed < 2 And numTries < maxTries
            Dim startIndex1 As Integer = Me.ReceivedXML.IndexOf("<Message>")
            Dim endIndex1 As Integer = Me.ReceivedXML.IndexOf("</Message>")
            Dim length1 As Integer = Me.ReceivedXML.Length
            Dim extractedXML1 As String = Me.ReceivedXML.Substring(startIndex1, endIndex1 + 10)
            If (startIndex < endIndex) And (extractedXML = extractedXML1) Then
                numTestsPassed = numTestsPassed + 1
            End If
            startIndex = startIndex1
            endIndex = endIndex1
            length = length1
            extractedXML = extractedXML1
            numTries = numTries + 1
        End While
        If numTestsPassed < 2 Then
            Return Nothing
        Else
            If endIndex > 0 And endIndex + 10 < length Then
                leftOver = Me.ReceivedXML.Substring(endIndex + 10, length - (endIndex + 10))
            End If
            Me.ReceivedXML = leftOver
            Return extractedXML
        End If
    End Function

    Private Function TxComplete()
        Dim Data = Me.Data.ToString().Trim()
        If (Data.Contains("<Tx>") And Data.Contains("</Tx>")) Or Data.Contains("<Tx/>") Then
            Return True
        Else
            Return False
        End If
    End Function

    Private Sub WriteLine(ByVal Message As String, ByRef Stream As System.Net.Sockets.NetworkStream)
        Dim Bytes() As Byte = System.Text.Encoding.UTF8.GetBytes(Message & ControlChars.CrLf)
        Me.WriteBytes(Bytes, Stream)
    End Sub

    Private Sub WriteBytes(ByVal Bytes() As Byte, ByRef Stream As System.Net.Sockets.NetworkStream)
        Stream.Write(Bytes, 0, Bytes.Count)
    End Sub

End Class
