Imports System.Xml.Serialization

Public Class Message

    Private PrivSuccess As String
    Private PrivCommand As String
    Private PrivParams As String
    Private PrivMessage As String

    Public Sub New()
    End Sub

    Public Sub New(ByVal RawXML As String)
        Dim objStreamReader As New IO.StringReader(RawXML)
        Dim x As New XmlSerializer(Me.GetType)
        Dim tempObj As New Message()
        tempObj = x.Deserialize(objStreamReader)
        objStreamReader.Close()
        Me.Success = tempObj.Success
        Me.Command = tempObj.Command
        Me.Params = tempObj.Params
        Me.Msg = tempObj.Msg
    End Sub

    Public Property Success() As String
        Get
            Success = PrivSuccess
        End Get
        Set(ByVal value As String)
            PrivSuccess = value
        End Set
    End Property

    Public Property Command() As String
        Get
            Command = PrivCommand
        End Get
        Set(ByVal value As String)
            PrivCommand = value
        End Set
    End Property

    Public Property Params() As String
        Get
            Params = PrivParams
        End Get
        Set(ByVal list As String)
            PrivParams = list
        End Set
    End Property

    Public Property Msg() As String
        Get
            Msg = PrivMessage
        End Get
        Set(ByVal value As String)
            PrivMessage = value
        End Set
    End Property

    Public Function ToXML() As String
        Dim objStreamWriter As New IO.StringWriter()
        Dim x As New XmlSerializer(Me.GetType)
        x.Serialize(objStreamWriter, Me)
        objStreamWriter.Flush()
        Dim RawXML As String = objStreamWriter.GetStringBuilder().ToString().Trim()
        objStreamWriter.Close()
        Return RawXML
    End Function

    Public Sub Send(ByRef Stream As System.Net.Sockets.NetworkStream)
        Dim RawXML As String = Me.ToXML()
        Dim Bytes() As Byte = System.Text.Encoding.UTF8.GetBytes(RawXML & ControlChars.CrLf)
        Stream.Write(Bytes, 0, Bytes.Count)
    End Sub
End Class
