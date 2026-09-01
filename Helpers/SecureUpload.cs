using System;
using System.IO;
using System.Web;
using MySqlConnector;

namespace DataTracking.Helpers
{
    // Shared, path-traversal-safe lookup of an uploaded file's real location on disk,
    // validated against the RecordFiles table (same rules FileHandler.ashx enforces).
    public static class SecureUpload
    {
        public static bool Resolve(HttpContext context, string recordId, string storedName, out string physicalPath, out string originalName)
        {
            physicalPath = null;
            originalName = null;

            Guid parsedId;
            if (string.IsNullOrWhiteSpace(recordId) || !Guid.TryParse(recordId, out parsedId) || string.IsNullOrWhiteSpace(storedName))
                return false;

            string normalizedId = parsedId.ToString("N");

            using (var conn = AppDb.Open())
            using (var cmd = new MySqlCommand(
                @"SELECT OriginalName FROM RecordFiles WHERE RecordId = @rid AND StoredName = @sn LIMIT 1", conn))
            {
                cmd.Parameters.AddWithValue("@rid", normalizedId);
                cmd.Parameters.AddWithValue("@sn", storedName);

                var result = cmd.ExecuteScalar();
                if (result == null) return false;

                originalName = result.ToString();
            }

            string safeStoredName = Path.GetFileName(storedName);
            string uploadRoot = context.Server.MapPath("~/App_Data/Uploads/" + normalizedId);
            string filePath = Path.Combine(uploadRoot, safeStoredName);

            if (!Path.GetFullPath(filePath).StartsWith(Path.GetFullPath(uploadRoot), StringComparison.OrdinalIgnoreCase) || !File.Exists(filePath))
                return false;

            physicalPath = filePath;
            return true;
        }
    }
}
