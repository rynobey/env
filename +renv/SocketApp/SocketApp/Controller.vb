Public Class Controller

    Public WorkerThreads As New Dictionary(Of String, WorkerThread)
    Private CurrentWorker As WorkerThread = GetWorker("Default")
    Private Server As SocketServer
    Private Processes As New Dictionary(Of String, Process)

    Public Sub New(ByVal Port As Integer)
        Me.Server = New SocketServer(Me, 8000, 1)
    End Sub

    Public Sub Start()
        Me.Server.Start()
    End Sub

    Public Function HandleMsg(ByRef msgThread As MessageThread, ByRef msg As Message) As Boolean
        Dim doSend As Boolean = True
        Select Case (msg.Command.ToLower())
            Case ("CreateWorker").ToLower()
                Me.CreateWorker(msg, msg.Params)
            Case ("StartProc").ToLower()
                Me.StartProc(msg, msg.Params)
            Case ("KillProcByName").ToLower()
                Me.KillProcByName(msg, msg.Params)
            Case ("ListWorkers").ToLower()
                Me.ListWorkers(msg)
            Case ("ListProcs").ToLower()
                Me.ListProcs(msg)
            Case ("GetCurrentWorker").ToLower()
                Me.GetCurrentWorker(msg)
            Case ("SetCurrentWorker").ToLower()
                Me.SetCurrentWorker(msg, msg.Params)
            Case ("GetValue").ToLower()
                Me.GetValue(msg, msg.Params)
            Case ("MkDir").ToLower()
                Me.MkDir(msg, msg.Params)
            Case ("DirExists").ToLower()
                Me.DirExists(msg, msg.Params)
            Case ("FileExists").ToLower()
                Me.FileExists(msg, msg.Params)
            Case ("CopyDir").ToLower()
                Me.CopyDir(msg, msg.Params)
            Case ("CopyFile").ToLower()
                Me.CopyFile(msg, msg.Params)
            Case ("RMDir").ToLower()
                Me.RMDir(msg, msg.Params)
            Case ("RMFile").ToLower()
                Me.RMFile(msg, msg.Params)
            Case Else
                If Me.CurrentWorker.HasCommand(msg.Command) Then
                    doSend = True
                    Dim cmd As New Message(msg.ToXML)
                    Me.CurrentWorker.Enqueue(cmd)
                    msg.Success = 1
                    msg.Command = ""
                    msg.Params = ""
                    msg.Msg = "Enqueued"
                Else
                    msg.Success = 0
                    msg.Msg = "Unknown command: " & msg.Command
                End If
        End Select
        If doSend Then
            msg.Send(msgThread.Stream)
        End If
        Return True
    End Function

    Public Function Authenticate() As Boolean
        Return True
    End Function

    Public Function GetWorker(ByVal Name As String)
        If Me.WorkerThreads.ContainsKey(Name) Then
            Return Me.WorkerThreads.Item(Name)
        Else
            Dim worker As New WorkerThread(Name)
            Me.WorkerThreads.Add(Name, worker)
            Return worker
        End If
    End Function

    ''Controller Command Functions
    Private Sub RMFile(ByRef msg As Message, ByVal filePath As String)
        'Try
        My.Computer.FileSystem.DeleteFile(filePath)
        'Catch ex As Exception
        'msg.Msg = "Failed to delete file"
        'End Try
    End Sub

    Private Sub RMDir(ByRef msg As Message, ByVal dirPath As String)
        'Try
        My.Computer.FileSystem.DeleteDirectory(dirPath, Microsoft.VisualBasic.FileIO.DeleteDirectoryOption.DeleteAllContents)
        'Catch ex As Exception
        'msg.Msg = "Failed to delete directory"
        'End Try
    End Sub

    Private Sub CopyFile(ByRef msg As Message, ByVal argString As String)
        Dim args As String() = argString.Split(";")
        Dim sourcePath As String = args(0)
        Dim index As Integer = sourcePath.LastIndexOf("\") + 1
        Dim sourceFileName As String = sourcePath.Substring(index, sourcePath.Length - index)
        Dim destPath As String = args(1) & "\" & sourceFileName
        If args.Length = 2 Then
            'Try
            My.Computer.FileSystem.CopyFile(sourcePath, destPath, False)
            'Catch ex As Exception
            'msg.Msg = "Failed to copy file"
            'End Try
        ElseIf args.Length = 3 Then
            If args(2) = "True" Then
                'Try
                My.Computer.FileSystem.CopyFile(sourcePath, destPath, True)
                'Catch ex As Exception
                'msg.Msg = "Failed to copy file"
                'End Try
            Else
                'Try
                My.Computer.FileSystem.CopyFile(sourcePath, destPath, False)
                'Catch ex As Exception
                'msg.Msg = "Failed to copy file"
                'End Try
            End If
        End If
    End Sub

    Private Sub CopyDir(ByRef msg As Message, ByVal argString As String)
        Dim args As String() = argString.Split(";")
        Dim sourcePath As String = args(0)
        Dim index As Integer = sourcePath.LastIndexOf("\") + 1
        Dim sourceDirName As String = sourcePath.Substring(index, sourcePath.Length - index)
        Dim destPath As String = args(1) & "\" & sourceDirName
        If args.Length = 2 Then
            'Try
            My.Computer.FileSystem.CopyDirectory(sourcePath, destPath, False)
            'Catch ex As Exception
            'msg.Msg = "Failed to copy directory"
            'End Try
        ElseIf args.Length = 3 Then
            If args(2) = "True" Then
                'Try
                My.Computer.FileSystem.CopyDirectory(sourcePath, destPath, True)
                'Catch ex As Exception
                'msg.Msg = "Failed to copy directory"
                'End Try
            Else
                'Try
                My.Computer.FileSystem.CopyDirectory(sourcePath, destPath, False)
                'Catch ex As Exception
                'msg.Msg = "Failed to copy directory"
                'End Try
            End If
        End If
    End Sub

    Private Sub MkDir(ByRef msg As Message, ByVal dirPath As String)
        If Not System.IO.Directory.Exists(dirPath) Then
            System.IO.Directory.CreateDirectory(dirPath)
            msg.Msg = "Directory created"
        Else
            msg.Msg = "Unable to create directory"
        End If
    End Sub

    Private Sub DirExists(ByRef msg As Message, ByVal dirPath As String)
        msg.Msg = "False"
        If System.IO.Directory.Exists(dirPath) Then
            msg.Msg = "True"
        End If
    End Sub

    Private Sub FileExists(ByRef msg As Message, ByVal filePath As String)
        msg.Msg = "False"
        If System.IO.File.Exists(filePath) Then
            msg.Msg = "True"
        End If
    End Sub

    Private Sub CreateWorker(ByRef msg As Message, ByVal Name As String)
        If Not Me.WorkerThreads.ContainsKey(Name) Then
            Dim worker As New WorkerThread(Name)
            Me.WorkerThreads.Add(Name, worker)
        Else
            msg.Msg = "Failed to create worker because a worker with that name already exists"
        End If
    End Sub

    Private Sub GetCurrentWorker(ByRef msg As Message)
        'Try
        msg.Msg = "Current Worker = " & Me.CurrentWorker.Name
        'Catch ex As Exception
        'msg.Msg = "Unable to get current worker"
        'End Try
    End Sub

    Private Sub SetCurrentWorker(ByRef msg As Message, ByVal Name As String)
        'Try
        Me.CurrentWorker = Me.GetWorker(Name)
        msg.Msg = "Current worker = " & Name
        'Catch ex As Exception
        'msg.Msg = "Unable to set current worker to """ & Name & """"
        'End Try
    End Sub

    Private Sub ListWorkers(ByRef msg As Message)
        Dim list As String = "CUR  " & "NAME" & vbTab & vbTab & "LAST CMD" & vbTab & "STATUS" & vbNewLine
        list = list & "================================================" & vbNewLine
        For Each Worker In Me.WorkerThreads
            Dim status As String
            Dim Cur As String
            If Me.CurrentWorker.Name = Worker.Key Then
                Cur = " *   "
            Else
                Cur = "     "
            End If
            If Worker.Value.IsBusy Then
                status = "Processing"
            Else
                status = "Sleeping"
            End If
            list = list & Cur & Worker.Key & vbTab & vbTab & Worker.Value.LastDequeuedCmd & vbTab & status & vbNewLine
        Next
        msg.Msg = list
    End Sub

    Private Sub ListProcs(ByRef msg As Message)
        Dim list As String = "NAME" & vbTab & "MEMORY(KB)" & vbTab & "CPU TIME" & vbTab & vbTab & "STATUS" & vbNewLine
        list = list & "=========================================================" & vbNewLine
        For Each proc In Me.Processes
            Try
                proc.Value.Refresh()
                Dim status As String
                If proc.Value.Responding Then
                    status = "Running"
                Else
                    status = "Not Responding"
                End If
                Dim mem As String = (proc.Value.WorkingSet64 / 1024).ToString()
                Dim time As String = proc.Value.TotalProcessorTime.ToString()
                list = list & proc.Key & vbTab & mem & "     " & vbTab & time & vbTab & status & vbNewLine
            Catch ex As Exception
                Me.Processes.Remove(proc.Key)
            End Try
        Next
        msg.Msg = list
    End Sub

    Private Sub GetValue(ByRef msg As Message, ByVal varName As String)
        msg.Msg = Me.CurrentWorker.GetScriptValue(varName).ToString()
    End Sub

    Private Sub StartProc(ByRef msg As Message, ByVal params As String)
        Dim args As String() = params.Split(";")
        Dim procName As String = args(0)
        Dim fileName As String = args(1)
        Dim arguments As String = args(2)
        Dim pi As New ProcessStartInfo
        pi.FileName = fileName
        pi.Arguments = arguments
        pi.WindowStyle = ProcessWindowStyle.Minimized
        If Me.Processes.ContainsKey(procName) Then
            msg.Msg = "A process with that name already exists!"
        Else
            Dim p As Process = Process.Start(pi)
            Me.Processes.Add(procName, p)
            msg.Msg = "Process Started!"
        End If
    End Sub

    Private Sub KillProcByName(ByRef msg As Message, ByVal params As String)
        Try
            Dim tempP As Process = Me.Processes.Item(params)
            Try
                tempP.Kill()
                Me.Processes.Remove(params)
                msg.Msg = "Process killed!"
            Catch ex As Exception
                Me.Processes.Remove(params)
                msg.Msg = ex.Message
            End Try
        Catch ex As Exception
            msg.Msg = "Unable to find a process with that name."
        End Try
    End Sub

End Class
