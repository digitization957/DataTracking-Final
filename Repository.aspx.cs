using System;
using System.Web.Script.Services;
using System.Web.Services;
using DataTracking.Helpers;
using MySqlConnector;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace DataTracking
{
    public partial class Repository : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
        }

        [WebMethod]
        [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
        public static string GetCategories()
        {
            var data = new JArray();
            using (var conn = AppDb.Open())
            using (var cmd = new MySqlCommand(
                "SELECT CategoryId, ParentId, Level, Name FROM Categories WHERE IsActive = 1 ORDER BY Level, Name", conn))
            using (var rdr = cmd.ExecuteReader())
            {
                while (rdr.Read())
                {
                    data.Add(new JObject
                    {
                        ["id"] = rdr["CategoryId"].ToString(),
                        ["parentId"] = rdr["ParentId"] == DBNull.Value ? null : rdr["ParentId"].ToString(),
                        ["level"] = Convert.ToInt32(rdr["Level"]),
                        ["name"] = rdr["Name"].ToString()
                    });
                }
            }
            return JsonConvert.SerializeObject(data);
        }

        [WebMethod]
        [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
        public static string GetFiles(string departmentId, string categoryId, string subCategoryId, string typeId, int level)
        {
            var data = new JArray();

            using (var conn = AppDb.Open())
            {
                string sql = @"
                    SELECT rf.FileId, rf.RecordId, rf.StoredName, rf.OriginalName, rf.FileExtension, rf.FileSizeBytes, rf.UploadedOn,
                           s.SubjectText, r.Remark
                    FROM recordfiles rf
                    INNER JOIN records r ON r.RecordId = rf.RecordId
                    INNER JOIN subjects s ON s.SubjectId = r.SubjectId
                    WHERE 1=1";

                var cmd = new MySqlCommand();
                cmd.Connection = conn;

                if (!string.IsNullOrEmpty(departmentId))
                {
                    sql += " AND r.DepartmentCategoryId=@dep";
                    cmd.Parameters.AddWithValue("@dep", departmentId);
                }
                if (!string.IsNullOrEmpty(categoryId))
                {
                    sql += " AND r.CategoryId=@cat";
                    cmd.Parameters.AddWithValue("@cat", categoryId);
                }
                if (!string.IsNullOrEmpty(subCategoryId))
                {
                    sql += " AND r.SubCategoryId=@sub";
                    cmd.Parameters.AddWithValue("@sub", subCategoryId);
                }
                if (!string.IsNullOrEmpty(typeId))
                {
                    sql += " AND r.TypeCategoryId=@type";
                    cmd.Parameters.AddWithValue("@type", typeId);
                }

                // Only match files that stop at exactly this level, so they don't also
                // show up again under a deeper child node in the tree.
                if (level == 1) sql += " AND r.CategoryId IS NULL";
                else if (level == 2) sql += " AND r.SubCategoryId IS NULL";
                else if (level == 3) sql += " AND r.TypeCategoryId IS NULL";

                sql += " ORDER BY rf.UploadedOn DESC";
                cmd.CommandText = sql;

                using (var rdr = cmd.ExecuteReader())
                {
                    while (rdr.Read())
                    {
                        data.Add(new JObject
                        {
                            ["fileId"] = rdr["FileId"].ToString(),
                            ["recordId"] = rdr["RecordId"].ToString(),
                            ["storedName"] = rdr["StoredName"].ToString(),
                            ["originalName"] = rdr["OriginalName"].ToString(),
                            ["extension"] = rdr["FileExtension"].ToString(),
                            ["uploadedOn"] = Convert.ToDateTime(rdr["UploadedOn"]).ToString("dd-MMM-yyyy HH:mm"),
                            ["subject"] = rdr["SubjectText"].ToString(),
                            ["remark"] = rdr["Remark"] == DBNull.Value ? "" : rdr["Remark"].ToString()
                        });
                    }
                }
            }

            return JsonConvert.SerializeObject(data);
        }
    }
}
