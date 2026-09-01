<%@ Page Title="Repository" Language="C#" AutoEventWireup="true" CodeBehind="Repository.aspx.cs" Inherits="DataTracking.Repository" %>

<!DOCTYPE html>
<html lang="en">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Repository - Data Tracking</title>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@600;700&family=Inter:wght@400;500;600&family=JetBrains+Mono:wght@400;500&display=swap" />
    <link href="Content/tokens.css" rel="stylesheet" />
    <link href="Content/app.css" rel="stylesheet" />
</head>
<body>
    <form id="form1" runat="server">
        <div class="topbar">
            <div class="topbar-brand"><div class="topbar-mark">DT</div><span>Data Tracking</span></div>
            <div class="topbar-right">
                <div class="topbar-nav">
                    <a href="Dashboard.aspx">Dashboard</a>
                    <a href="Upload.aspx">Upload</a>
                    <a href="Repository.aspx" aria-current="page">Repository</a>
                    <div class="nav-dropdown" id="masterNav">
                        <button type="button" class="nav-dropdown-toggle" id="masterToggle">Master <span class="chev">&#9662;</span></button>
                        <div class="nav-dropdown-menu">
                            <a href="Master.aspx">Dropdown options</a>
                        </div>
                    </div>
                </div>
                <div class="nav-dropdown" id="userNav">
                    <button type="button" class="user-trigger" id="userToggle">
                        <span class="user-avatar" id="userAvatar">?</span>
                        <span class="user-name" id="lblUser">Loading…</span>
                        <span class="chev">&#9662;</span>
                    </button>
                    <div class="nav-dropdown-menu user-pop">
                        <div class="user-pop-head">
                            <span class="user-avatar user-avatar-lg" id="userAvatarLg">?</span>
                            <div>
                                <div class="user-pop-name" id="userPopName">Loading…</div>
                                <div class="user-pop-sub" id="userPopRole">—</div>
                            </div>
                        </div>
                        <hr />
                        <div class="user-pop-row"><span class="l">Token</span><span class="v mono" id="userToken">—</span></div>
                        <hr />
                        <button type="button" class="user-pop-logout" id="btnLogout">Logout</button>
                    </div>
                </div>
            </div>
        </div>

        <div class="app-content">
            <div class="panel-head" style="margin-bottom:var(--space-lg);">
                <h2>Repository</h2>
                <p class="lead">Expand a <span id="lblLvl1lc">department</span> to explore <span id="lblLvl2lc">categories</span>, <span id="lblLvl3lc">sub-categories</span> and <span id="lblLvl4lc">types</span>. Files appear inside each <span id="lblLvl4lc2">type</span>.</p>
            </div>

            <div class="panel">
                <div class="tree-toolbar">
                    <div class="tree-search">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><circle cx="11" cy="11" r="7"/><path d="M21 21l-4.3-4.3"/></svg>
                        <input type="text" id="txtTreeSearch" placeholder="Search departments, categories, sub-categories or types…" autocomplete="off" />
                    </div>
                    <button type="button" id="btnToggleAll" class="tree-toggle-btn">
                        <svg class="tree-toggle-icon" id="toggleAllIcon" viewBox="0 0 24 24"><use href="#ic-chevron"/></svg>
                        <span id="toggleAllLabel">Expand all</span>
                    </button>
                </div>

                <div class="tree-panel" id="treeRoot"></div>
                <div class="tree-no-match" id="treeNoMatch">No matches.</div>
            </div>
        </div>

        <div class="file-hover-pop" id="fileHoverPop">
            <div class="fhp-head">
                <span class="ext-chip" id="fhpExt"></span>
                <div class="fhp-subject" id="fhpSubject"></div>
            </div>
            <div class="fhp-field">
                <span class="fhp-label">Remark</span>
                <div class="fhp-remark" id="fhpRemark"></div>
            </div>
            <div class="fhp-meta">Uploaded <span id="fhpUploaded"></span></div>
        </div>
    </form>

    <svg style="display:none">
      <symbol id="ic-chevron" viewBox="0 0 24 24"><path d="M9 6l6 6-6 6" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/></symbol>
      <symbol id="ic-folder" viewBox="0 0 24 24"><path d="M4 6.5A1.5 1.5 0 0 1 5.5 5h4l2 2.5h7A1.5 1.5 0 0 1 20 9v8.5A1.5 1.5 0 0 1 18.5 19h-13A1.5 1.5 0 0 1 4 17.5v-11Z" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/></symbol>
    </svg>

    <script src="Scripts/jquery-3.7.0.min.js"></script>
    <script src="Scripts/auth.js"></script>
    <script>
        var categoryData = [];
        var currentAuth = null;

        function esc(s) {
            return String(s).replace(/[&<>"]/g, function (c) {
                return c === "&" ? "&amp;" : c === "<" ? "&lt;" : c === ">" ? "&gt;" : "&quot;";
            });
        }

        function childrenOf(parentId) {
            return categoryData.filter(function (c) {
                return String(c.parentId) === String(parentId);
            });
        }

        function extClass(ext) {
            ext = (ext || "").toLowerCase().replace(".", "");
            if (ext === "pdf") return "ext-pdf";
            if (ext === "xlsx" || ext === "xls") return "ext-xlsx";
            if (ext === "docx" || ext === "doc") return "ext-docx";
            if (ext === "msg") return "ext-msg";
            return "ext-default";
        }

        function fileRowHTML(file) {
            var ext = (file.extension || "").replace(".", "");
            var isMsg = ext.toLowerCase() === "msg";
            var handler = isMsg ? "MsgViewer.aspx" : "FileHandler.ashx";
            var url = handler + "?recordId=" + encodeURIComponent(file.recordId) +
                "&file=" + encodeURIComponent(file.storedName);

            if (isMsg && currentAuth) {
                url += "&token=" + encodeURIComponent(currentAuth.token) + "&role=" + encodeURIComponent(currentAuth.role);
            }

            return '<a class="tree-file-row" href="' + url + '" target="_blank"' +
                ' data-subject="' + esc(file.subject || "") + '"' +
                ' data-remark="' + esc(file.remark || "") + '"' +
                ' data-uploaded="' + esc(file.uploadedOn || "") + '"' +
                ' data-ext="' + esc(ext) + '">' +
                '<span class="ext-chip ' + extClass(ext) + '">' + esc(ext || "file") + '</span>' +
                '<span class="tree-file-name">' + esc(file.originalName) + '</span>' +
                '<span class="tree-file-meta">' + esc(file.uploadedOn) + '</span>' +
                '</a>';
        }

        function ancestorChain(typeId) {
            var chain = { departmentId: "", categoryId: "", subCategoryId: "", typeId: "" };
            var cur = categoryData.find(function (c) { return String(c.id) === String(typeId); });

            while (cur) {
                if (cur.level === 1) chain.departmentId = cur.id;
                if (cur.level === 2) chain.categoryId = cur.id;
                if (cur.level === 3) chain.subCategoryId = cur.id;
                if (cur.level === 4) chain.typeId = cur.id;

                cur = cur.parentId ?
                    categoryData.find(function (c) { return String(c.id) === String(cur.parentId); }) :
                    null;
            }

            return chain;
        }

        function buildNode(item, domIdPrefix) {
            var domId = domIdPrefix + "-" + item.id;
            var kids = childrenOf(item.id);
            var count = kids.length ? '<span class="node-count">' + kids.length + '</span>' : "";
            var kidsHTML = kids.map(function (k) { return buildNode(k, domId); }).join("");
            var filesHTML = '<div class="tree-file-list" id="' + domId + '-files" data-loaded="0"><div class="tree-file-loading">Loading files…</div></div>';

            return '<div class="tree-node lvl-' + item.level + '" data-name="' + esc(item.name.toLowerCase()) + '">' +
                '<button type="button" class="node-row" aria-expanded="false" aria-controls="' + domId + '-kids" data-id="' + item.id + '" data-level="' + item.level + '">' +
                '<svg class="twisty"><use href="#ic-chevron"/></svg>' +
                '<svg class="folder-icon"><use href="#ic-folder"/></svg>' +
                '<span class="node-name">' + esc(item.name) + '</span>' + count +
                '</button>' +
                '<div class="node-children" id="' + domId + '-kids"><div class="inner">' + kidsHTML + filesHTML + '</div></div>' +
                '</div>';
        }

        function renderTree() {
            var roots = categoryData.filter(function (c) { return c.level === 1; });
            $("#treeRoot").html(roots.map(function (r) { return buildNode(r, "t"); }).join(""));
        }

        function loadFilesFor($row) {
            var domId = $row.attr("aria-controls").replace(/-kids$/, "");
            var $box = $("#" + domId + "-files");

            if ($box.data("loaded") === 1) return;
            $box.data("loaded", 1);

            var chain = ancestorChain($row.data("id"));
            chain.level = $row.data("level");

            $.ajax({
                type: "POST",
                url: "Repository.aspx/GetFiles",
                data: JSON.stringify(chain),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (res) {
                    var files = JSON.parse(res.d);
                    $box.empty();

                    if (files.length === 0) {
                        $box.addClass("is-empty");
                        return;
                    }

                    $box.append('<div class="files-eyebrow">Files · ' + files.length + '</div>');
                    files.forEach(function (f) { $box.append(fileRowHTML(f)); });
                },
                error: function () {
                    $box.html('<div class="tree-file-empty">Could not load files.</div>');
                    $box.data("loaded", 0);
                }
            });
        }

        $(document).on("click", ".node-row", function () {
            var $row = $(this);
            var open = $row.attr("aria-expanded") === "true";

            $row.attr("aria-expanded", String(!open));
            $("#" + $row.attr("aria-controls")).toggleClass("is-open", !open);

            if (!open) {
                loadFilesFor($row);
            }
        });

        function setToggleAllState(expanded) {
            $("#toggleAllLabel").text(expanded ? "Collapse all" : "Expand all");
            $("#btnToggleAll").toggleClass("is-on", expanded);
        }

        $(document).on("click", "#btnToggleAll", function () {
            var expand = !$(this).hasClass("is-on");

            $(".node-row").each(function () {
                var $row = $(this);
                $row.attr("aria-expanded", String(expand));
                $("#" + $row.attr("aria-controls")).toggleClass("is-open", expand);

                if (expand) loadFilesFor($row);
            });

            setToggleAllState(expand);
        });

        $(document).on("input", "#txtTreeSearch", function () {
            var query = $.trim($(this).val()).toLowerCase();
            var anyVisible = false;

            var $nodes = $(".tree-node").get().reverse();

            $nodes.forEach(function (n) {
                var $n = $(n);
                var selfMatch = !query || $n.data("name").toString().indexOf(query) !== -1;
                var $kids = $n.children(".node-children");
                var hasVisibleChild = $kids.find("> .inner > .tree-node:not([hidden])").length > 0;
                var show = !query || selfMatch || hasVisibleChild;

                $n.prop("hidden", !show);
                if (show) anyVisible = true;

                if (query && show) {
                    var $row = $n.children(".node-row");
                    $row.attr("aria-expanded", "true");
                    $kids.addClass("is-open");
                }
            });

            $("#treeNoMatch").toggleClass("show", query.length > 0 && !anyVisible);
        });

        var $fileHoverPop = null;
        var hoverPopTimer = null;
        var REMARK_PREVIEW_MAX = 160;

        function truncate(text, max) {
            text = text || "";
            return text.length > max ? text.slice(0, max).trim() + "…" : text;
        }

        function positionHoverPop($row) {
            var rect = $row[0].getBoundingClientRect();
            var pop = $fileHoverPop[0];
            var top = rect.bottom + 8;
            var left = rect.left;

            $fileHoverPop.css({ top: top + "px", left: left + "px", visibility: "hidden" }).addClass("show");
            var popRect = pop.getBoundingClientRect();

            if (popRect.right > window.innerWidth - 12) { left = Math.max(12, window.innerWidth - popRect.width - 12); }
            if (popRect.bottom > window.innerHeight - 12) { top = rect.top - popRect.height - 8; }

            $fileHoverPop.css({ top: top + "px", left: left + "px", visibility: "visible" });
        }

        $(document).on("mouseenter", ".tree-file-row", function () {
            var $row = $(this);
            clearTimeout(hoverPopTimer);

            hoverPopTimer = setTimeout(function () {
                var ext = ($row.data("ext") || "").toString();
                $("#fhpExt").attr("class", "ext-chip " + extClass(ext)).text(ext || "file");
                $("#fhpSubject").text($row.data("subject") || "(No subject)");
                var remark = $row.data("remark");
                $("#fhpRemark").text(remark ? truncate(remark, REMARK_PREVIEW_MAX) : "No remark added.").toggleClass("is-empty", !remark);
                $("#fhpUploaded").text($row.data("uploaded") || "—");
                positionHoverPop($row);
            }, 220);
        });

        $(document).on("mouseleave", ".tree-file-row", function () {
            clearTimeout(hoverPopTimer);
            $fileHoverPop.removeClass("show");
        });

        function pluralize(s) {
            s = s || "";
            if (/[a-z]y$/i.test(s)) return s.slice(0, -1) + "ies";
            if (/s$/i.test(s)) return s;
            return s + "s";
        }

        function applyRepoLabels() {
            $.ajax({
                type: "POST", url: "Master.aspx/GetCategoryLevelNames",
                data: "{}", contentType: "application/json; charset=utf-8", dataType: "json",
                success: function (res) {
                    var names = JSON.parse(res.d);
                    var l1 = names[1] || "Department", l2 = names[2] || "Category",
                        l3 = names[3] || "Sub-Category", l4 = names[4] || "Type";

                    $("#lblLvl1lc").text(l1.toLowerCase());
                    $("#lblLvl2lc").text(pluralize(l2).toLowerCase());
                    $("#lblLvl3lc").text(pluralize(l3).toLowerCase());
                    $("#lblLvl4lc").text(pluralize(l4).toLowerCase());
                    $("#lblLvl4lc2").text(l4.toLowerCase());

                    $("#txtTreeSearch").attr("placeholder",
                        "Search " + pluralize(l1).toLowerCase() + ", " + pluralize(l2).toLowerCase() +
                        ", " + pluralize(l3).toLowerCase() + " or " + pluralize(l4).toLowerCase() + "…");
                }
            });
        }

        function loadCategories() {
            $.ajax({
                type: "POST",
                url: "Repository.aspx/GetCategories",
                data: "{}",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (res) {
                    categoryData = JSON.parse(res.d);
                    renderTree();
                }
            });
        }

        $(function () {
            $fileHoverPop = $("#fileHoverPop");
            DTAuth.bindDropdown("#masterToggle", "#masterNav");
            DTAuth.bindDropdown("#userToggle", "#userNav");
            DTAuth.bindGlobalDropdownClose();

            var auth = DTAuth.resolve();
            if (!auth) return;
            currentAuth = auth;

            DTAuth.renderUserMenu(auth.token, auth.role, auth.token);
            $("#btnLogout").on("click", DTAuth.logout);

            $.ajax({
                type: "POST", url: "Dashboard.aspx/GetUserInfo",
                data: JSON.stringify({ token: auth.token }), contentType: "application/json; charset=utf-8", dataType: "json",
                success: function (res) {
                    var data = JSON.parse(res.d);
                    if (data.found) { DTAuth.renderUserMenu(data.name, auth.role, auth.token); }
                }
            });

            applyRepoLabels();
            loadCategories();
        });
    </script>
</body>
</html>
