Imports System.Reflection

Public Class SocketServer

    Private Controller As Controller
    Private Socket As System.Net.Sockets.TcpListener
    Private MaxConnections As Integer
    Private Thread As System.Threading.Thread
    Private MessageThreads As New Dictionary(Of Integer, MessageThread)
    Private isProcessing As Boolean = False
    Private isStarted As Boolean = False

    Public Sub New(ByRef Controller As Controller, ByVal Port As Integer, ByVal MaxConnections As Integer)
        Me.Controller = Controller
        Me.Socket = New System.Net.Sockets.TcpListener(Port)
        Me.MaxConnections = MaxConnections
        Me.Thread = New Threading.Thread(AddressOf Me.ProcessLoop)
    End Sub

    Public Sub Start()
        Me.Socket.Start()
        Me.Thread.Start()
        While Not Me.IsStarted
            System.Threading.Thread.Sleep(100)
        End While
    End Sub

    Public Function IsBusy()
        Return Me.isProcessing
    End Function

    Private Sub Init()
        'Me.WriteLine("Connected.")
    End Sub

    Private Sub ProcessLoop()
        Do
            If Me.isStarted = False Then
                Me.isProcessing = True
                Me.isStarted = True
            End If
            Me.Init()
            'Try
            Dim Client = Socket.AcceptTcpClient()
            Client.ReceiveBufferSize = 8192000
            Dim Messenger = Me.GetFreeMessageThread()
            If Not (Messenger Is Nothing) Then
                Messenger.Enqueue(Client)
            Else
                Console.WriteLine("Message discarded!")
            End If
            'Catch ex As Exception
            'System.Console.WriteLine(ex.Message)
            'End Try
        Loop
    End Sub

    Private Function GetFreeMessageThread() As MessageThread
        Dim FreeMessageThread As MessageThread = Nothing
        For Each Key In Me.MessageThreads.Keys
            If Not Me.MessageThreads.Item(Key).IsBusy() Then
                FreeMessageThread = Me.MessageThreads.Item(Key)
                Exit For
            End If
        Next
        If FreeMessageThread Is Nothing Then
            If Me.MessageThreads.Count < Me.MaxConnections Then
                Dim NewThread As New MessageThread(Me.Controller, Me)
                Me.MessageThreads.Add(Me.MessageThreads.Count + 1, NewThread)
                FreeMessageThread = NewThread
            Else
                FreeMessageThread = Me.MessageThreads.Item(1)
            End If
        End If
        Return FreeMessageThread
    End Function

    Public Function GetClientIP(ByRef NetStream As System.Net.Sockets.NetworkStream) As String
        Dim PublicIP As String = ""
        'Try
        ' Get the clients IP address using reflection
        Dim pi As PropertyInfo = _
            NetStream.GetType.GetProperty( _
            "Socket", BindingFlags.NonPublic Or BindingFlags.Instance)
        If Not pi Is Nothing Then
            PublicIP = pi.GetValue(NetStream, _
            Nothing).RemoteEndPoint.ToString.Split(":")(0)
        End If
        'Catch ex As System.Exception
        'PublicIP = String.Empty
        'End Try
        Return PublicIP
    End Function

End Class
