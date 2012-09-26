Option Explicit

Sub Main()
Dim fileName As String
Dim fileText As String
fileName = "testFile"
fileText = "testText"
Dim file As Long
file = FreeFile
Open fileName For Append As #file
Print #file, fileText
Close #file
End Sub