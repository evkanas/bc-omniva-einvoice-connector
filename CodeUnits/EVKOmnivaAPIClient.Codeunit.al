codeunit 70101 "EVK Omniva API Client"
{
    procedure GetConnectionSettings(var ServiceUrl: Text; var AuthorizationToken: Text)
    var
        OmnivaSetup: Record "EVK Omniva Setup";
    begin
        OmnivaSetup.Get();

        case OmnivaSetup.Environment of
            OmnivaSetup.Environment::Prod:
                begin
                    OmnivaSetup.TestField(Authorization);
                    OmnivaSetup.TestField("API URL");
                    AuthorizationToken := OmnivaSetup.Authorization;
                    ServiceUrl := OmnivaSetup."API URL";
                end;
            OmnivaSetup.Environment::Dev:
                begin
                    OmnivaSetup.TestField("Authorization Dev");
                    OmnivaSetup.TestField("API URL Dev");
                    AuthorizationToken := OmnivaSetup."Authorization Dev";
                    ServiceUrl := OmnivaSetup."API URL Dev";
                end;
            else
                Error(OmnivaSettingsAreMissingErr);
        end;
    end;

    procedure CreateRequestText(AuthorizationToken: Text; var RequestText: Text; ElementName: Text)
    begin
        RequestText := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" ';
        RequestText += 'xmlns:erp="http://e-arvetekeskus.eu/erp">';
        RequestText += '<soapenv:Header/>';
        RequestText += '<soapenv:Body>';
        RequestText += '<erp:' + ElementName + ' format="AXAPTA" replace="NO" parse="YES" authPhrase="' + AuthorizationToken + '">';
        RequestText += '</erp:' + ElementName + '>';
        RequestText += '</soapenv:Body>';
        RequestText += '</soapenv:Envelope>';
    end;

    procedure CreateDocument(RequestText: Text; var Document: XmlDocument; var Envelope: XmlNodeList; var BodyElements: XmlNodeList; var DocumentNodes: XmlNodeList; var EnvelopeNode: XmlNode; var BodyNode: XmlNode)
    begin
        if not XmlDocument.ReadFrom(RequestText, Document) then
            Error(InvalidXmlErr);

        DocumentNodes := Document.GetChildNodes();
        if not DocumentNodes.Get(1, EnvelopeNode) then
            Error(MissingSoapEnvelopeErr);

        Envelope := EnvelopeNode.AsXmlElement().GetChildElements();
        if not Envelope.Get(2, BodyNode) then
            Error(MissingSoapBodyErr);

        BodyElements := BodyNode.AsXmlElement().GetChildElements();
    end;

    procedure SendDocument(var RequestText: Text; var Document: XmlDocument; ServiceUrl: Text; AutomaticProcess: Boolean)
    var
        OmnivaSetup: Record "EVK Omniva Setup";
        ResponseText: Text;
    begin
        OmnivaSetup.Get();
        Document.WriteTo(RequestText);

        SendRequest(
            RequestText,
            ServiceUrl,
            OmnivaSetup."Download File" and not AutomaticProcess,
            OmnivaSetup."Download File" and not AutomaticProcess,
            ResponseText);
    end;

    procedure SendRequest(RequestText: Text; ServiceUrl: Text; DownloadRequest: Boolean; DownloadResponse: Boolean; var ResponseText: Text)
    var
        HttpClient: HttpClient;
        HttpContent: HttpContent;
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
        Headers: HttpHeaders;
    begin
        if DownloadRequest then
            ExportText(RequestText, 'soap_req.xml', true);

        HttpRequestMessage.SetRequestUri(ServiceUrl);
        HttpRequestMessage.Method('POST');
        HttpContent.WriteFrom(RequestText);
        HttpContent.GetHeaders(Headers);
        Headers.Remove('Content-Type');
        Headers.Add('Content-Type', 'text/xml; charset=utf-8');
        HttpRequestMessage.Content := HttpContent;

        if not HttpClient.Send(HttpRequestMessage, HttpResponseMessage) then
            Error(HttpTransportErr);

        HttpResponseMessage.Content.ReadAs(ResponseText);

        if DownloadResponse then
            ExportText(ResponseText, 'soap_res.xml', true);

        if not HttpResponseMessage.IsSuccessStatusCode() then
            Error(
                HttpResponseErr,
                HttpResponseMessage.HttpStatusCode(),
                HttpResponseMessage.ReasonPhrase(),
                CopyStr(ResponseText, 1, 1024));
    end;

    procedure ExportDiagnosticFile(Value: Text; FileName: Text; ShowDialog: Boolean)
    begin
        ExportText(Value, FileName, ShowDialog);
    end;

    local procedure ExportText(Value: Text; FileName: Text; ShowDialog: Boolean)
    var
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
        OutputStream: OutStream;
    begin
        TempBlob.CreateOutStream(OutputStream, TextEncoding::UTF8);
        OutputStream.WriteText(Value);
        FileManagement.BLOBExport(TempBlob, FileName, ShowDialog);
    end;

    var
        OmnivaSettingsAreMissingErr: Label 'Omniva settings are missing.', Comment = 'lt-LT="Trūksta „Omniva“ nustatymų."';
        InvalidXmlErr: Label 'The SOAP request is not valid XML.', Comment = 'lt-LT="SOAP užklausa nėra tinkamas XML dokumentas."';
        MissingSoapEnvelopeErr: Label 'The SOAP envelope is missing.', Comment = 'lt-LT="SOAP dokumente nerastas „Envelope“ elementas."';
        MissingSoapBodyErr: Label 'The SOAP body is missing.', Comment = 'lt-LT="SOAP dokumente nerastas „Body“ elementas."';
        HttpTransportErr: Label 'The HTTP request could not be sent.', Comment = 'lt-LT="Nepavyko išsiųsti HTTP užklausos."';
        HttpResponseErr: Label 'Omniva returned HTTP status %1 (%2). Response: %3', Comment = 'lt-LT="„Omniva“ grąžino HTTP būseną %1 (%2). Atsakymas: %3"';
}
