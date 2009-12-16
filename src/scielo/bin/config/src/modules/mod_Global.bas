Attribute VB_Name = "ModGlobal"
Option Explicit

Public Const SECTION_SEP = "%"
Public Const CODE_SEP = "-"
'Uso de isisdll
Public AppHandle    As Long
Public Const delim1 = "<"
Public Const delim2 = ">"
Public Const pathsep = "\"

Public issueidparts As New ColCode
    
Public ConfigLabels As ClLabels
Public Fields As ColFields
Public Months As ColIdiomMeses
Public IdiomsInfo As ColIdiom

'Variaveis de configuracao
Public SciELOPath As String
Public VolSiglum As String
Public NoSiglum As String
Public SupplVolSiglum  As String
Public SupplNoSiglum  As String
Public BrowserPath  As String
Public CurrIdiomHelp As String
Public IssueCloseDenied As Integer
Public TitleCloseDenied As Integer
Public PathsConfigurationFile As String

Public Paths As ColFileInfo


'Public IdiomHelp   As ColIdiom
Public Msg As New ClMsg
Public SepLinha As String


Public NodeFatherKey() As String
Public NodeChild() As String
Public NodeInfo() As String
Public FileNotRequired() As Boolean
Public Counter As Long

Public CodeStudyArea As ColCode
Public CodeAlphabet As ColCode
Public CodeLiteratureType As ColCode
Public CodeTreatLevel As ColCode
Public CodePubLevel As ColCode
Public CodeFrequency As ColCode
Public codeStatus As ColCode
Public CodeTxtLanguage As ColCode
Public CodeAbstLanguage As ColCode
Public CodeCountry As ColCode
Public CodeState As ColCode
Public CodeUsersubscription As ColCode
Public CodeFTP As ColCode
Public CodeCCode As ColCode
Public CodeIdxRange As ColCode
Public CodeStandard As ColCode
Public CodeScheme As ColCode
Public CodeIssStatus As ColCode
Public CodeIdiom As ColCode
Public CodeTOC As ColCode
Public CodeScieloNet As ColCode
Public CodeISSNType As ColCode

Public journal As ClsJournal

Public ErrorMessages As ClsErrorMessages

Public isisfn As Long



Property Get NotRequiredFile(i As Long) As Boolean
    NotRequiredFile = FileNotRequired(i)
End Property

Function TagContent(ByVal conteudo As String, ByVal tag As Long) As String
    Dim ComTag As String
    
    If tag = 0 Then
        MsgBox "TagContent: tag=0. Conteudo=" + conteudo
    ElseIf conteudo = "" Then
        'MsgBox "TagContent: Conteudo=" + conteudo
    Else
        conteudo = RmNewLineInStr(conteudo)
        ComTag = delim1 + CStr(tag) + delim2 + conteudo + delim1 + "/" + CStr(tag) + delim2 + SepLinha
    End If
    TagContent = ComTag
End Function

Function TagSubf(ByVal conteudo As String, ByVal subf As String) As String
    If conteudo <> "" Then TagSubf = "^" + subf + conteudo
End Function


Private Sub Main()
    Dim CodeDB As ClFileInfo
    
   
    isisfn = FreeFile
    
    Open App.path + "\isis.log" For Output As isisfn
    
    AppHandle = IsisAppNew()
    Call IsisAppDebug(AppHandle, DEBUG_LIGHT)
    
    SepLinha = Chr(13) + Chr(10)
        
    If ConfigGet Then
                
        ChangeInterfaceIdiom = CurrIdiomHelp
        
        
        Set ErrorMessages = New ClsErrorMessages
        ErrorMessages.load ("langs\" + CurrIdiomHelp + "_err.txt")
        
        Set Months = New ColIdiomMeses
        Months.ReadMonthTable
    
        Set CodeDB = Paths("NewCode Database")
        Call LoadCodes(CodeDB, "", "ccode", CodeCCode)
        
        Set CodeDB = Paths("Code Database")
        Call LoadCodes(CodeDB, "", "standard", CodeStandard)
        Call LoadCodes(CodeDB, "", "scielonet", CodeScieloNet)
        
        
        FormMenuPrin.OpenMenu
        
        Set journalDAO = New ClsJournalDAO
        
        
        
        'FormConfig.Show vbModal
    End If
    
    
End Sub

Function ConfigGet() As Boolean
    Dim fn As Long
    Dim key As String
    
    
    fn = FreeFile
    Open App.path + "\scipath.ini" For Input As fn
    Input #fn, SciELOPath
    Close fn
    
    fn = FreeFile(1)
    Open App.path + "\value.ini" For Input As fn
    'Input #fn, Key, SciELOPath
    Input #fn, key, VolSiglum
    Input #fn, key, NoSiglum
    Input #fn, key, SupplVolSiglum
    Input #fn, key, SupplNoSiglum
    Input #fn, key, BrowserPath
    Input #fn, key, CurrIdiomHelp
    Input #fn, key, IssueCloseDenied
    Input #fn, key, TitleCloseDenied
    Input #fn, key, PathsConfigurationFile
    Close fn


    ConfigGet = True
End Function


Sub ConfigSet()
    Dim fn As Long
    
    fn = FreeFile(1)
    Open "value.ini" For Output As fn
'    Write #fn, "SciELOPath", SciELOPath
    Write #fn, "SglVol", VolSiglum
    Write #fn, "SglNo", NoSiglum
    Write #fn, "SglVolSuppl", SupplVolSiglum
    Write #fn, "SglNoSuppl", SupplNoSiglum
    Write #fn, "BrowserPath", BrowserPath
    Write #fn, "CurrIdiomHelp", CurrIdiomHelp
    Write #fn, "IssueCloseDenied", IssueCloseDenied
    Write #fn, "TitleCloseDenied", TitleCloseDenied
    Write #fn, "PathsConfigurationFile", PathsConfigurationFile
    Close fn
End Sub

Function CheckDateISO(Issue_DateISO As String) As Boolean
    Dim Ret As Boolean
    Dim Data As Date
    Dim dia1 As String
    Dim mes1 As String
    Dim ano1 As String
    Dim dia2 As String
    Dim mes2 As String
    Dim ano2 As String
    
    If Len(Issue_DateISO) <> 8 Then
        
    Else
        dia1 = Mid(Issue_DateISO, 7, 2)
        mes1 = Mid(Issue_DateISO, 5, 2)
        ano1 = Mid(Issue_DateISO, 1, 4)
        
        If (CLng(dia1) > 31) And (CLng(dia1) < 0) Then
            'MsgBox ("Invalid day")
        ElseIf (CLng(mes1) > 12) And (CLng(mes1) < 0) Then
            'MsgBox ("Invalid month.")
        Else
            Ret = True
        End If
    End If
    If Not Ret Then MsgBox ConfigLabels.getLabel("MsgInvalidDATEISO"), vbCritical
    CheckDateISO = Ret
End Function




Function issueId(vol As String, supplvol As String, Num As String, SupplNum As String, part As String) As String
    Dim Ret As String
    
    If Len(vol) > 0 Then Ret = Ret + VolSiglum + vol
    If Len(supplvol) > 0 Then Ret = Ret + SupplVolSiglum + supplvol
    If Len(Num) > 0 Then Ret = Ret + NoSiglum + Num
    If Len(SupplNum) > 0 Then Ret = Ret + SupplNoSiglum + SupplNum
    If Len(part) > 0 Then Ret = Ret + part
    
    issueId = Ret
End Function
Function IssueKey(vol As String, supplvol As String, Num As String, SupplNum As String) As String
    Dim Ret As String
    
    Ret = Ret + VolSiglum + vol
    Ret = Ret + SupplVolSiglum + supplvol
    Ret = Ret + NoSiglum + Num
    Ret = Ret + SupplNoSiglum + SupplNum
    
    IssueKey = Ret
End Function

Function MsgIssueId(vol As String, supplvol As String, Num As String, SupplNum As String, IseqNo As String) As String
    Dim Ret As String
    
    If Len(vol) > 0 Then Ret = Ret + "Volume = " + vol + SepLinha
    If Len(supplvol) > 0 Then Ret = Ret + "Volume Suppl = " + supplvol + SepLinha
    If Len(Num) > 0 Then Ret = Ret + "Number = " + Num + SepLinha
    If Len(SupplNum) > 0 Then Ret = Ret + "Number Suppl = " + SupplNum + SepLinha
    If Len(IseqNo) > 0 Then Ret = Ret + "Seq. Number = " + IseqNo + SepLinha
    MsgIssueId = Ret
End Function




Sub LoadCodes(CodeDB As ClFileInfo, Idiom As String, key As String, Code As ColCode)
    Dim isisCode As ClIsisdll
    Dim mfn As Long
    Dim mfns() As Long
    Dim q As Long
    Dim i As Long
    Dim aux As String
    Dim p As Long
    Dim p2 As Long
    Dim itemCode As ClCode
    Dim val As String
    Dim cod As String
    Dim exist As Boolean
    
    
    With CodeDB
    Set Code = New ColCode
    Set isisCode = New ClIsisdll
    If isisCode.Inicia(.path, .FileName, .key) Then
        If isisCode.IfCreate(.FileName) Then
            q = isisCode.MfnFind(Idiom + CODE_SEP + key, mfns)
            While (i < q) And (mfn = 0)
                i = i + 1
                aux = isisCode.UsePft(mfns(i), "if v1^*='" + key + "' and v1^l='" + Idiom + "' then (v2^v|;|,v2^c|;;|) fi")
                If Len(aux) > 0 Then mfn = mfns(i)
            Wend
            
            If mfn > 0 Then
                
                Set itemCode = New ClCode
                
                p2 = InStr(aux, ";;")
                p = InStr(aux, ";")
                
                While p2 > 0
                    val = Mid(aux, 1, p - 1)
                    cod = Mid(aux, p + 1, p2 - p - 1)
                
'                    Set itemCode = Code.Item(val, exist)
'                    If Not exist Then
'                        Set itemCode = Code.Add(val)
'                        itemCode.Value = val
'                        itemCode.Code = cod
'                    End If
                    
                    Set itemCode = Code.item(cod, exist)
                    If Not exist Then
                        Set itemCode = Code.add(cod)
                        itemCode.value = val
                        itemCode.Code = cod
                    End If
                
                    aux = Mid(aux, p2 + 2)
                    p2 = InStr(aux, ";;")
                    p = InStr(aux, ";")
                Wend
            End If
        End If
    End If
    End With
End Sub


Property Let ChangeInterfaceIdiom(Idiom As String)
    Dim i As Long
    Dim x As ClIdiom
    Dim CodeDB As ClFileInfo
    
    CurrIdiomHelp = Idiom
    
    Set Paths = New ColFileInfo
    Set Paths = ReadPathsConfigurationFile(PathsConfigurationFile)
    
    'ReadDirTree (CurrIdiomHelp + "_files.ini")
    'MakeTree

    Set ConfigLabels = New ClLabels
    ConfigLabels.SetLabels (Idiom)
    Set Fields = New ColFields
    Fields.SetLabels (Idiom)
    
    
    loadIssueIdPart Idiom
Set CodeDB = New ClFileInfo

    Set CodeDB = Paths("Code Database")
    
    Call LoadCodes(CodeDB, Idiom, "idiom interface", CodeIdiom)
    Call LoadCodes(CodeDB, Idiom, "alphabet of title", CodeAlphabet)
    Call LoadCodes(CodeDB, Idiom, "literature type", CodeLiteratureType)
    Call LoadCodes(CodeDB, Idiom, "treatment level", CodeTreatLevel)
    Call LoadCodes(CodeDB, Idiom, "publication level", CodePubLevel)
    Call LoadCodes(CodeDB, Idiom, "frequency", CodeFrequency)
    Call LoadCodes(CodeDB, Idiom, "status", codeStatus)
    Call LoadCodes(CodeDB, Idiom, "country", CodeCountry)
    Call LoadCodes(CodeDB, Idiom, "state", CodeState)
    
    Call LoadCodes(CodeDB, Idiom, "usersubscription", CodeUsersubscription)
    Call LoadCodes(CodeDB, Idiom, "issn type", CodeISSNType)
    Call LoadCodes(CodeDB, Idiom, "ftp", CodeFTP)
        
    Call LoadCodes(CodeDB, Idiom, "language", CodeAbstLanguage)
    Call LoadCodes(CodeDB, Idiom, "language", CodeTxtLanguage)
    Call LoadCodes(CodeDB, Idiom, "issue status", CodeIssStatus)
    Call LoadCodes(CodeDB, Idiom, "scheme", CodeScheme)
    
    Call LoadCodes(CodeDB, "", "table of contents", CodeTOC)
    
    
    Set CodeDB = Paths("NewCode Database")
    Call LoadCodes(CodeDB, Idiom, "study area", CodeStudyArea)
    'Call LoadCodes(CodeDB, Idiom, "scheme", CodeScheme)
            
    
    Set IdiomsInfo = New ColIdiom
    Set x = New ClIdiom
    For i = 1 To CodeIdiom.count
        'Set x = IdiomsInfo(CodeIdiom(i).Code)
        'If x Is Nothing Then
            Set x = IdiomsInfo.add(CodeIdiom(i).Code, CodeIdiom(i).value, CodeTOC(CodeIdiom(i).Code).value, CodeIdiom(i).Code)
        'Else
        '    IdiomsInfo.item(CodeIdiom(i).Code).label = CodeIdiom(i).value
        '    IdiomsInfo.item(CodeIdiom(i).Code).More = CodeTOC(CodeIdiom(i).Code).value
        'End If
    Next
    
End Property


Function ReadPathsConfigurationFile(file As String) As ColFileInfo
    Dim fn As Long
    Dim lineread As String
    Dim item As ClFileInfo
    Dim key As String
    Dim path As String
    Dim CollectionPaths As ColFileInfo
    Dim req As Long
    
    fn = FreeFile
    Open file For Input As fn
        
    Set CollectionPaths = New ColFileInfo
    
    While Not EOF(fn)
        Line Input #fn, lineread
        If InStr(lineread, "=") > 0 Then
            key = Mid(lineread, 1, InStr(lineread, "=") - 1)
            path = Mid(lineread, InStr(lineread, "=") + 1)
            req = InStr(path, ",required")
            If req > 0 Then
                path = Mid(path, 1, req - 1)
                
            End If
            Set item = CollectionPaths.add(key)
            item.key = key
            If InStr(path, "\") > 0 Then
                item.path = Mid(path, 1, InStrRev(path, "\") - 1)
                item.FileName = Mid(path, InStrRev(path, "\") + 1)
            Else
                item.path = ""
                item.FileName = path
            End If
            item.required = (req > 0)
        End If
    Wend
    Close fn
    Set ReadPathsConfigurationFile = CollectionPaths
End Function
Sub loadIssueIdPart(CurrCodeIdiom As String)
    Dim fn As Long
    Dim key As String
    Dim value As String
    Dim obj As ClCode
    
    Set issueidparts = New ColCode
    fn = FreeFile
    Open App.path + "\tables\" + CurrCodeIdiom + "\part.ini" For Input As fn
    While Not EOF(fn)
        Input #fn, key, value
        
        Set obj = New ClCode
        obj.Index = issueidparts.count + 1
        obj.value = value
        obj.Code = key
        issueidparts.add key, obj
         
    Wend
    Close fn
End Sub

Sub openHelp(path As String, Optional file As String)
    Dim f As String
    If Len(file) > 0 Then f = "\" & CurrIdiomHelp & file
    Call Shell("cmd.exe /k start " & path & f, vbHide)
    
End Sub
