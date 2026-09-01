<%@ Page Title="Mail" Language="C#" AutoEventWireup="true" CodeBehind="MsgViewer.aspx.cs" Inherits="DataTracking.MsgViewer" %>

<!DOCTYPE html>
<html lang="en">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Mail - Data Tracking</title>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@600;700&family=Inter:wght@400;500;600&family=JetBrains+Mono:wght@400;500&display=swap" />
    <link href="Content/tokens.css" rel="stylesheet" />
    <link href="Content/app.css" rel="stylesheet" />
</head>
<body>
    <form id="form1" runat="server">
        <div class="topbar">
            <div class="topbar-brand"><div class="topbar-mark">DT</div><span>Data Tracking</span></div>
            <a class="mail-back-link" id="mailBackLink" href="Repository.aspx">&larr; Back to Repository</a>
        </div>

        <div class="app-content" id="mailApp">
            <div class="mail-loading" id="mailLoading">Loading mail&hellip;</div>
            <div class="mail-error" id="mailError" style="display:none;"></div>
            <div id="mailRoot" style="display:none;"></div>
        </div>
    </form>

    <script src="Scripts/jquery-3.7.0.min.js"></script>
    <script src="Scripts/auth.js"></script>
    <script>
        function esc(s) {
            return String(s == null ? "" : s).replace(/[&<>"]/g, function (c) {
                return c === "&" ? "&amp;" : c === "<" ? "&lt;" : c === ">" ? "&gt;" : "&quot;";
            });
        }

        function extClass(ext) {
            ext = (ext || "").toLowerCase();
            if (ext === "pdf") return "ext-pdf";
            if (ext === "xlsx" || ext === "xls") return "ext-xlsx";
            if (ext === "docx" || ext === "doc") return "ext-docx";
            if (ext === "msg") return "ext-msg";
            return "ext-default";
        }

        function extOf(name) {
            var i = (name || "").lastIndexOf(".");
            return i === -1 ? "" : name.slice(i + 1);
        }

        function fmtSize(bytes) {
            if (!bytes) return "0 KB";
            var kb = bytes / 1024;
            return kb < 1024 ? Math.max(1, Math.round(kb)) + " KB" : (kb / 1024).toFixed(1) + " MB";
        }

        function attachmentRowHTML(a, recordId, file) {
            var ext = extOf(a.fileName);
            var url = "MsgAttachmentHandler.ashx?recordId=" + encodeURIComponent(recordId) +
                "&file=" + encodeURIComponent(file) + "&index=" + a.index;

            return '<a class="attach-row" href="' + url + '">' +
                '<span class="ext-chip ' + extClass(ext) + '">' + esc(ext || "file") + '</span>' +
                '<span class="attach-name">' + esc(a.fileName) + '</span>' +
                '<span class="attach-size">' + esc(fmtSize(a.sizeBytes)) + '</span>' +
                '</a>';
        }

        function renderMail(m, recordId, file) {
            var crumbHTML = (m.crumb || []).map(function (c) { return esc(c); }).join(' <span class="sep">&rsaquo;</span> ') +
                ' <span class="sep">&rsaquo;</span> <b>' + esc(m.originalFileName) + '</b>';

            var fromHTML = '<span class="name">' + esc(m.fromName || m.fromEmail || "Unknown sender") + '</span>' +
                (m.fromEmail ? '<span class="addr">' + esc(m.fromEmail) + '</span>' : "");

            var attachHTML = (m.attachments || []).map(function (a) { return attachmentRowHTML(a, recordId, file); }).join("");
            var attachCount = (m.attachments || []).length;

            var html =
                '<div class="crumb">' + crumbHTML + '</div>' +
                '<div class="mail-card">' +
                    '<div class="mail-head">' +
                        '<h1>' + esc(m.subject || "(No subject)") + '</h1>' +
                        '<div class="mail-meta">' +
                            '<div class="mail-meta-row"><span class="l">From</span><span class="v">' + fromHTML + '</span></div>' +
                            (m.to ? '<div class="mail-meta-row"><span class="l">To</span><span class="v">' + esc(m.to) + '</span></div>' : "") +
                            (m.cc ? '<div class="mail-meta-row"><span class="l">Cc</span><span class="v">' + esc(m.cc) + '</span></div>' : "") +
                            '<div class="mail-meta-row date"><span class="l">Date</span><span class="v">' + esc(m.sentOn || "Unknown") + '</span></div>' +
                        '</div>' +
                    '</div>' +
                    '<div class="mail-body">' + esc(m.bodyText || "(No body)") + '</div>' +
                    (attachCount ? '<div class="mail-attachments"><span class="label">Attachments &middot; ' + attachCount + '</span><div class="attach-list">' + attachHTML + '</div></div>' : "") +
                '</div>' +
                '<div class="safety-strip">' +
                    '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 3l8 4v5c0 4.5-3 7.5-8 9-5-1.5-8-4.5-8-9V7l8-4Z"/><path d="M9.5 12l1.8 1.8L15 9.8"/></svg>' +
                    '<span>Parsed and shown as read-only text &mdash; no scripts, macros or embedded HTML from the original mail are executed.</span>' +
                '</div>' +
                '<div class="original-file"><span>Parsed from ' + esc(m.originalFileName) + '</span></div>';

            $("#mailRoot").html(html).show();
        }

        $(function () {
            var auth = DTAuth.resolve();
            if (!auth) return;

            $("#mailBackLink").attr("href",
                "Repository.aspx?token=" + encodeURIComponent(auth.token) + "&role=" + encodeURIComponent(auth.role));

            var params = new URLSearchParams(window.location.search);
            var recordId = params.get("recordId");
            var file = params.get("file");

            if (!recordId || !file) {
                $("#mailLoading").hide();
                $("#mailError").text("Missing file reference.").show();
                return;
            }

            $.ajax({
                type: "POST",
                url: "MsgViewer.aspx/GetMsgDetails",
                data: JSON.stringify({ recordId: recordId, file: file }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (res) {
                    var r = JSON.parse(res.d);
                    $("#mailLoading").hide();
                    if (!r.success) { $("#mailError").text(r.message || "Could not open this mail.").show(); return; }
                    renderMail(r, recordId, file);
                },
                error: function () {
                    $("#mailLoading").hide();
                    $("#mailError").text("Could not open this mail.").show();
                }
            });
        });
    </script>
</body>
</html>
