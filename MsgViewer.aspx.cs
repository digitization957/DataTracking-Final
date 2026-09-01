using System;
using System.IO;
using System.Web.Script.Services;
using System.Web.Services;
using DataTracking.Helpers;
using MySqlConnector;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace DataTracking
{
    public partial class MsgViewer : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
        }

        [WebMethod]
        [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
        public static string GetMsgDetails(string recordId, string file)
        {
            string filePath, originalName;

            if (!SecureUpload.Resolve(System.Web.HttpContext.Current, recordId, file, out filePath, out originalName) ||
                Path.GetExtension(filePath).ToLowerInvariant() != ".msg")
            {
                return JsonConvert.SerializeObject(new { success = false, message = "File not found." });
            }

            ParsedMsg parsed;
            try
            {
                parsed = MsgParser.Parse(filePath);
            }
            catch
            {
                return JsonConvert.SerializeObject(new { success = false, message = "Could not read this .msg file." });
            }

            var crumb = GetCrumb(recordId);
            var attachments = new JArray();
            foreach (var a in parsed.Attachments)
            {
                attachments.Add(new JObject { ["index"] = a.Index, ["fileName"] = a.FileName, ["sizeBytes"] = a.SizeBytes });
            }

            var result = new JObject
            {
                ["success"] = true,
                ["crumb"] = crumb,
                ["originalFileName"] = originalName,
                ["subject"] = parsed.Subject,
                ["fromName"] = parsed.FromName,
                ["fromEmail"] = parsed.FromEmail,
                ["to"] = parsed.To,
                ["cc"] = parsed.Cc,
                ["sentOn"] = parsed.SentOn.HasValue ? parsed.SentOn.Value.ToString("ddd, dd MMM yyyy HH:mm") : null,
                ["bodyText"] = parsed.BodyText,
                ["attachments"] = attachments
            };

            return JsonConvert.SerializeObject(result);
        }

        private static JArray GetCrumb(string recordId)
        {
            var crumb = new JArray();
            Guid parsedId;
            if (!Guid.TryParse(recordId, out parsedId)) return crumb;

            using (var conn = AppDb.Open())
            using (var cmd = new MySqlCommand(
                @"SELECT d.Name AS DepartmentName, c.Name AS CategoryName, sc.Name AS SubCategoryName, t.Name AS TypeName
                  FROM Records r
                  LEFT JOIN Categories d ON d.CategoryId = r.DepartmentCategoryId
                  LEFT JOIN Categories c ON c.CategoryId = r.CategoryId
                  LEFT JOIN Categories sc ON sc.CategoryId = r.SubCategoryId
                  LEFT JOIN Categories t ON t.CategoryId = r.TypeCategoryId
                  WHERE r.RecordId = @rid
                  LIMIT 1", conn))
            {
                cmd.Parameters.AddWithValue("@rid", parsedId.ToString("N"));

                using (var rdr = cmd.ExecuteReader())
                {
                    if (rdr.Read())
                    {
                        foreach (var col in new[] { "DepartmentName", "CategoryName", "SubCategoryName", "TypeName" })
                        {
                            if (rdr[col] != DBNull.Value) crumb.Add(rdr[col].ToString());
                        }
                    }
                }
            }

            return crumb;
        }
    }
}
