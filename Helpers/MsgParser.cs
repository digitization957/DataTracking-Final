using System;
using System.Collections.Generic;
using System.Linq;

namespace DataTracking.Helpers
{
    public class ParsedMsgAttachment
    {
        public int Index { get; set; }
        public string FileName { get; set; }
        public int SizeBytes { get; set; }
    }

    public class ParsedMsg
    {
        public string Subject { get; set; }
        public string FromName { get; set; }
        public string FromEmail { get; set; }
        public string To { get; set; }
        public string Cc { get; set; }
        public DateTimeOffset? SentOn { get; set; }
        public string BodyText { get; set; }
        public List<ParsedMsgAttachment> Attachments { get; set; }
    }

    // Parses .msg files fully offline (no network calls) via the vendored MsgReader library.
    public static class MsgParser
    {
        public static ParsedMsg Parse(string filePath)
        {
            using (var msg = new MsgReader.Outlook.Storage.Message(filePath))
            {
                var attachments = new List<ParsedMsgAttachment>();
                var index = 0;

                foreach (var item in msg.Attachments)
                {
                    var att = item as MsgReader.Outlook.Storage.Attachment;
                    if (att == null || att.Hidden || att.IsInline) continue;

                    attachments.Add(new ParsedMsgAttachment
                    {
                        Index = index,
                        FileName = att.FileName,
                        SizeBytes = att.Data != null ? att.Data.Length : 0
                    });
                    index++;
                }

                return new ParsedMsg
                {
                    Subject = msg.Subject,
                    FromName = msg.Sender != null ? msg.Sender.DisplayName : null,
                    FromEmail = msg.Sender != null ? msg.Sender.Email : null,
                    To = msg.GetEmailRecipients(MsgReader.Outlook.RecipientType.To, false, false),
                    Cc = msg.GetEmailRecipients(MsgReader.Outlook.RecipientType.Cc, false, false),
                    SentOn = msg.SentOn,
                    BodyText = msg.BodyText,
                    Attachments = attachments
                };
            }
        }

        // Re-parses and returns the raw bytes of one non-hidden, non-inline attachment by its display index.
        public static ParsedMsgAttachment GetAttachmentBytes(string filePath, int index, out byte[] data)
        {
            using (var msg = new MsgReader.Outlook.Storage.Message(filePath))
            {
                var visible = msg.Attachments
                    .OfType<MsgReader.Outlook.Storage.Attachment>()
                    .Where(a => !a.Hidden && !a.IsInline)
                    .ToList();

                if (index < 0 || index >= visible.Count)
                {
                    data = null;
                    return null;
                }

                var att = visible[index];
                data = att.Data;
                return new ParsedMsgAttachment { Index = index, FileName = att.FileName, SizeBytes = data != null ? data.Length : 0 };
            }
        }
    }
}
