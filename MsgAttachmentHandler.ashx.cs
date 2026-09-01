using System;
using System.IO;
using System.Linq;
using System.Web;
using DataTracking.Helpers;

namespace DataTracking
{
    // Streams a single attachment extracted from inside a .msg file (parsed fully offline).
    public class MsgAttachmentHandler : IHttpHandler
    {
        public bool IsReusable { get { return false; } }

        public void ProcessRequest(HttpContext context)
        {
            string recordId = context.Request.QueryString["recordId"];
            string storedName = context.Request.QueryString["file"];
            int index;

            if (!int.TryParse(context.Request.QueryString["index"], out index) || index < 0)
            {
                context.Response.StatusCode = 400;
                return;
            }

            string filePath, originalName;
            if (!SecureUpload.Resolve(context, recordId, storedName, out filePath, out originalName) ||
                Path.GetExtension(filePath).ToLowerInvariant() != ".msg")
            {
                context.Response.StatusCode = 404;
                return;
            }

            byte[] data;
            var attachment = MsgParser.GetAttachmentBytes(filePath, index, out data);

            if (attachment == null || data == null)
            {
                context.Response.StatusCode = 404;
                return;
            }

            string safeName = new string(attachment.FileName.Where(c => c != '"' && c != '\r' && c != '\n').ToArray());
            if (string.IsNullOrWhiteSpace(safeName)) safeName = "attachment";

            context.Response.Clear();
            context.Response.ContentType = "application/octet-stream";
            context.Response.Headers["X-Content-Type-Options"] = "nosniff";
            context.Response.AddHeader("Content-Disposition", "attachment; filename=\"" + safeName + "\"");
            context.Response.BinaryWrite(data);
            context.Response.End();
        }
    }
}
