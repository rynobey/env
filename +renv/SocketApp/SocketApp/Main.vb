Imports System.Diagnostics
Module Main

    Sub Main()
        System.Console.WriteLine("Hello!")
        Dim c As New Controller(8000)
        c.Start()
        System.Console.ReadLine()
    End Sub

End Module
