Imports System.Text.RegularExpressions
Imports System.Threading

Public Class WorkerThread

    Public Name As String
    Public Tasks As Queue
    Private Thread As System.Threading.Thread
    Private SC As MSScriptControl.ScriptControl
    Private IsStarted As Boolean = False
    Private IsProcessing As Boolean = False
    Public LastDequeuedCmd As String = "InitWorker"
    Private lockObj As New Object()
    Public msgThread As MessageThread

    Public Sub New(ByVal Name As String)
        Me.Name = Name
        Me.Tasks = New Queue
        System.Console.WriteLine("Worker Thread Started: " & Name)
        Me.Thread = New Threading.Thread(AddressOf Me.ProcessLoop)
    End Sub

    Public Sub Enqueue(ByRef msg As Message)
        Me.Tasks.Enqueue(msg)
        Me.ResumeThread()
    End Sub

    Public Sub ResumeThread()
        If Me.IsStarted And Not Me.IsBusy() Then
            'Me.Thread.Resume()
            Monitor.Enter(Me.lockObj)
            Monitor.Pulse(Me.lockObj)
            Monitor.Exit(Me.lockObj)
        ElseIf Not Me.IsStarted Then
            Me.Start()
        End If
    End Sub

    Public Sub Start()
        Me.Thread.Start()
        While Not Me.IsStarted
            System.Threading.Thread.Sleep(100)
        End While
    End Sub

    Public Function IsBusy()
        Return Me.IsProcessing
    End Function

    Private Sub Suspend()
        Me.IsProcessing = False
        'Me.Thread.Suspend()
        Monitor.Enter(Me.lockObj)
        Me.IsProcessing = Monitor.Wait(Me.lockObj)
        Monitor.Exit(Me.lockObj)
    End Sub

    Private Sub Init()
        If Me.SC Is Nothing Then
            Me.SC = New MSScriptControl.ScriptControl
            Me.SC.Timeout = -1
            Me.SC.Language = "VBScript"
        End If
    End Sub

    Private Sub ProcessLoop()
        Do
            If Me.IsStarted = False Then
                Me.IsProcessing = True
                Me.IsStarted = True
            End If
            Me.Init()
            If Me.Tasks.Count > 0 Then
                Dim msg As Message = Me.Tasks.Dequeue()
                Me.LastDequeuedCmd = msg.Command
                'Try
                Me.HandleMsg(msg)
                'Catch ex As Exception
                'System.Console.WriteLine(ex.Message)
                'End Try
            End If
            If Me.Tasks.Count = 0 Then
                Me.Suspend()
            End If
        Loop
    End Sub

    Public Function GetScriptValue(ByVal varName As String) As Object
        Try
            If Me.SC Is Nothing Then
                Me.ResumeThread()
            End If
            Return Me.SC.Eval(varName)
        Catch
            Return ("")
        End Try
    End Function

    Public Function HasCommand(ByVal cmdName As String) As Boolean
        Select Case cmdName
            Case "VBScript"
                Return True
            Case "RunProcess"
                Return True
            Case Else
                Return False
        End Select
    End Function

    Private Function HandleMsg(ByRef msg As Message) As Boolean
        Select Case msg.Command
            Case "VBScript"
                Me.VBScript(msg, msg.Params)
            Case "VBScriptReset"
                Me.VBScriptReset(msg)
            Case "RunProcess"
                Me.StartCST(msg)

        End Select
        Return True
    End Function

    ''Worker Command Functions
    Private Sub VBScript(ByRef msg As Message, ByVal script As String)
        Try
            Me.SC.ExecuteStatement(script)
            Me.SC.Error.Clear()
        Catch ex As Exception
            msg.Msg = "An error occurred while executing VBScript: " & ex.Message
            msg.Send(Me.msgThread.Stream)
        End Try
    End Sub

    Private Sub VBScriptReset(ByRef msg As Message)
        'Try
        If Me.SC Is Nothing Then
            Me.ResumeThread()
        End If
        Me.SC.Reset()
        'Catch ex As Exception

        'End Try
    End Sub

    Private Sub StartCST(ByRef msg As Message)
        Me.RunProcess(msg, "C:\Program Files (x86)\CST STUDIO SUITE 2011\CST DESIGN ENVIRONMENT.exe", "-m")
    End Sub

    Private Sub GetCSTMemory(ByRef msg As Message)

    End Sub

    Private Sub GetCSTCPUTime(ByRef msg As Message)

    End Sub

    Private Sub GetCSTResponding(ByRef msg As Message)

    End Sub

    Private Sub KillCST(ByRef msg As Message)

    End Sub

    Private Sub CSTIsRunning(ByRef msg As Message)

    End Sub

    Private Sub RunProcess(ByRef msg As Message, ByVal fileName As String, ByVal arguments As String)
        Dim pi As New ProcessStartInfo
        pi.FileName = fileName
        pi.Arguments = arguments
        pi.WindowStyle = ProcessWindowStyle.Minimized
        Dim p As Process = Process.Start(pi)
        Thread.Sleep(10000)
        Console.WriteLine(p.MachineName)
        Console.WriteLine(p.PeakWorkingSet64)
        Console.WriteLine(p.TotalProcessorTime)
        msg.Msg = "Process Started!"
        msg.Send(Me.msgThread.Stream)
    End Sub

End Class
