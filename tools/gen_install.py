"""Generates the Bifrost Nornir data take-over codeunit.

Reads the app's table sources plus the migration namemap (old id -> new id, old name -> new name)
and writes app/src/Install/AppTakeover.Codeunit.al. Every table pair, field list and enum
remap is derived from the sources - no id is typed by hand.

Usage:  python tools/gen_install.py --namemap <namemap.tsv> [--check]
"""
import argparse
import io
import os
import re
import sys

AP = argparse.ArgumentParser()
AP.add_argument("--namemap", required=True)
AP.add_argument("--offset", type=int, default=-40500,
                help="new object id - old object id (the whole app shifted by one offset)")
AP.add_argument("--check", action="store_true", help="only verify the generated file is up to date")
ARGS = AP.parse_args()

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "app", "src")
OUT = os.path.join(SRC, "Install", "AppTakeover.Codeunit.al")

TAKEOVER_ID = 10035604
OLD_APP_ID = "755c941b-c4e5-4d19-938f-9c56c25708a9"

# Tables that are pure execution logs / transient buffers are never copied.
SKIP_TABLES = {"Playbook Instance ori", "Playbook Step Log ori"}

# Values that stored an object id or an enum ordinal from an old object-id range.
LEGACY_NORNIR = (10076035, 10076134, -40500)      # this app's legacy range
LEGACY_CORE = (10075485, 10075984, 2400)          # Origo Cloud Events Core -> Bifrost Foundation
REMAPS = {
    ("Scheduled Entry ori", "Object ID to Run"): [LEGACY_NORNIR],
    ("Playbook Step ori", "Message Type"): [LEGACY_NORNIR, LEGACY_CORE],
}

PERMISSION_SETS = [
    ("CE Orchestrator ori", "BIFROST Nornir ori"),
    ("CE Orch. Setup ori", "BIFROST NrnSetup ori"),
    ("CE Orch. Mgt ori", "BIFROST NrnMgt ori"),
    ("CE PlaybookAdmin ori", "BIFROST PlaybAdm ori"),
    ("CE Playbook View ori", "BIFROST PlaybVw ori"),
]

# The Telegram chat id lives on a table extension of the Bifrost user setup table.
USER_SETUP = dict(old_table=10075509, new_table=10077909, old_field=10076035, new_field=10035535)

FIELD_RE = re.compile(r'^[ \t]*field\((\d+);\s*("([^"]+)"|[A-Za-z_]\w*)\s*;\s*([^)]*)\)[ \t]*$', re.M)


def read(path):
    return io.open(path, encoding="utf-8-sig").read()


def table_files():
    for dp, _, fs in os.walk(SRC):
        for f in fs:
            if f.endswith(".Table.al"):
                yield os.path.join(dp, f)


def parse_table(path):
    text = read(path)
    m = re.search(r'^table\s+(\d+)\s+"([^"]+)"', text, re.M)
    if not m:
        return None
    tid, name = int(m.group(1)), m.group(2)
    fields = []
    for fm in FIELD_RE.finditer(text):
        fno = int(fm.group(1))
        fname = fm.group(3) or fm.group(2)
        ftype = fm.group(4).strip()
        body_start = text.index("{", fm.end())
        depth, i = 0, body_start
        while i < len(text):
            if text[i] == "{":
                depth += 1
            elif text[i] == "}":
                depth -= 1
                if depth == 0:
                    break
            i += 1
        body = text[body_start:i]
        is_flow = "FieldClass = FlowField" in body or "FieldClass = FlowFilter" in body
        is_blob = ftype.lower() in ("blob", "media", "mediaset")
        fields.append((fno, fname, ftype, is_flow, is_blob))
    return name, tid, fields


def load_namemap(path):
    """new object name -> old object name. A name shared by a page and a table appears once in the
    namemap, so ids are not taken from here; they are derived from the single range offset."""
    out = {}
    for line in io.open(path, encoding="utf-8"):
        parts = line.rstrip("\n").split("\t")
        if len(parts) < 6 or parts[0] != "app":
            continue
        out.setdefault(parts[5], parts[4])
    return out


def q(n):
    return '"%s"' % n


def proc_name(table_name):
    return re.sub(r"[^A-Za-z0-9]", "", table_name[:-4])


def gen():
    nm = load_namemap(ARGS.namemap)
    tables = []
    for p in sorted(table_files()):
        parsed = parse_table(p)
        if not parsed:
            continue
        name, tid, fields = parsed
        if name in SKIP_TABLES or name not in nm:
            continue
        old_name = nm[name]
        old_id = tid - ARGS.offset
        tables.append((name, old_name, old_id, tid, fields))
    tables.sort(key=lambda t: t[3])

    L = []
    a = L.append
    a("namespace Origo.Bifrost.Nornir;")
    a("")
    a("using Origo.Bifrost;")
    a("using System.Reflection;")
    a("using System.Security.AccessControl;")
    a("using System.Telemetry;")
    a("using System.Utilities;")
    a("")
    a("/// <summary>")
    a("/// Takes the data of the published <c>Origo Cloud Events Orchestrator</c> app over into")
    a("/// Bifrost Nornir the first time this app is installed in a company. For every (old table,")
    a("/// new table) pair the old table is copied with <c>DataTransfer</c> when it still exists in")
    a("/// the database and the new table is empty; BLOB fields, which DataTransfer does not support,")
    a("/// are copied afterwards with a RecordRef pass. Values that stored an object id or an enum")
    a("/// ordinal from an old object-id range are shifted into the new ranges, and every user that")
    a("/// held one of the old permission sets is granted the matching Bifrost one. Execution logs")
    a("/// (playbook instances and step logs) are not copied.")
    a("/// Generated by <c>tools/gen_install.py</c> - do not edit by hand.")
    a("/// </summary>")
    a('codeunit %d "App Takeover ori"' % TAKEOVER_ID)
    a("{")
    a("    Access = Internal;")
    a("")
    a("    /// <summary>")
    a("    /// Runs the whole take-over. Called from the install codeunit before the app registers")
    a("    /// its own job queues, so the copied schedules are already present.")
    a("    /// </summary>")
    a("    internal procedure TakeOverAll()")
    a("    begin")
    for t in tables:
        a("        TakeOver%s();" % proc_name(t[0]))
    a("        TakeOverTelegramChatId();")
    a("        TakeOverAccessControl();")
    a("    end;")

    for name, old_name, old_id, new_id, fields in tables:
        copyable = [(f[0], f[1]) for f in fields if not f[3] and not f[4]]
        blobs = [(f[0], f[1]) for f in fields if f[4] and not f[3]]
        remaps = [(f[1], r) for f in fields for r in REMAPS.get((name, f[1]), [])]
        a("")
        a("    /// <summary>Copies <c>%s</c> (%d) into <c>%s</c> (%d).</summary>" % (old_name, old_id, name, new_id))
        a("    local procedure TakeOver%s()" % proc_name(name))
        a("    var")
        a("        Target: Record %s;" % q(name))
        a("        OldRef: RecordRef;")
        a("        DataTransfer: DataTransfer;")
        if blobs:
            a("        BlobFieldNos: List of [Integer];")
        a("    begin")
        a("        if not OldTableExists(%d) then" % old_id)
        a("            exit;")
        a("        if not Target.IsEmpty() then")
        a("            exit;")
        a("        DataTransfer.SetTables(%d, Database::%s);" % (old_id, q(name)))
        a("        OldRef.Open(%d);" % old_id)
        for fno, _ in copyable:
            a("        if OldRef.FieldExist(%d) then" % fno)
            a("            DataTransfer.AddFieldValue(%d, %d);" % (fno, fno))
        a("        OldRef.Close();")
        a("        DataTransfer.UpdateAuditFields(false);")
        a("        DataTransfer.CopyRows();")
        for fno, _ in blobs:
            a("        BlobFieldNos.Add(%d);" % fno)
        if blobs:
            a("        CopyBlobFields(%d, Database::%s, BlobFieldNos);" % (old_id, q(name)))
        for fname, (frm, to, off) in remaps:
            a("        ShiftIntegerField(Database::%s, Target.FieldNo(%s), %d, %d, %d);"
              % (q(name), q(fname), frm, to, off))
        a("        LogTakeOver('%s', Target.Count());" % name)
        a("    end;")

    a("")
    a("    /// <summary>Copies the Telegram chat id from the published app's user setup extension.</summary>")
    a("    local procedure TakeOverTelegramChatId()")
    a("    var")
    a("        OldRef: RecordRef;")
    a("        NewRef: RecordRef;")
    a("        OldField: FieldRef;")
    a("        NewField: FieldRef;")
    a("        Copied: Integer;")
    a("    begin")
    a("        if not OldTableExists(%d) then" % USER_SETUP["old_table"])
    a("            exit;")
    a("        OldRef.Open(%d);" % USER_SETUP["old_table"])
    a("        if not OldRef.FieldExist(%d) then begin" % USER_SETUP["old_field"])
    a("            OldRef.Close();")
    a("            exit;")
    a("        end;")
    a("        NewRef.Open(%d);" % USER_SETUP["new_table"])
    a("        if NewRef.FindSet(true) then")
    a("            repeat")
    a("                NewField := NewRef.Field(%d);" % USER_SETUP["new_field"])
    a("                if Format(NewField.Value()) = '' then")
    a("                    if FindMatchingRow(NewRef, OldRef) then begin")
    a("                        OldField := OldRef.Field(%d);" % USER_SETUP["old_field"])
    a("                        if Format(OldField.Value()) <> '' then begin")
    a("                            NewField.Value(OldField.Value());")
    a("                            NewRef.Modify(false);")
    a("                            Copied += 1;")
    a("                        end;")
    a("                    end;")
    a("            until NewRef.Next() = 0;")
    a("        NewRef.Close();")
    a("        OldRef.Close();")
    a("        if Copied > 0 then")
    a("            LogTakeOver('User Setup ori.Telegram Chat ID ori', Copied);")
    a("    end;")
    a("")
    a("    /// <summary>Grants the Bifrost permission sets to every user that held an old one.</summary>")
    a("    local procedure TakeOverAccessControl()")
    a("    var")
    a("        Migrated: Integer;")
    a("    begin")
    for old_ps, new_ps in PERMISSION_SETS:
        a("        Migrated += MigrateRole('%s', '%s');" % (old_ps, new_ps))
    a("        if Migrated > 0 then")
    a("            LogTakeOver('Access Control', Migrated);")
    a("    end;")
    a("")
    a("    local procedure MigrateRole(OldRoleId: Code[20]; NewRoleId: Code[20]) Migrated: Integer")
    a("    var")
    a('        OldAccessControl: Record "Access Control";')
    a('        NewAccessControl: Record "Access Control";')
    a("        NewAppId: Guid;")
    a("    begin")
    a("        NewAppId := AppId();")
    a('        OldAccessControl.SetRange("Role ID", OldRoleId);')
    a('        OldAccessControl.SetRange("App ID", OldAppId());')
    a("        if OldAccessControl.FindSet() then")
    a("            repeat")
    a("                if not NewAccessControl.Get(")
    a('                    OldAccessControl."User Security ID", NewRoleId, OldAccessControl."Company Name",')
    a("                    OldAccessControl.Scope, NewAppId)")
    a("                then begin")
    a("                    NewAccessControl.Init();")
    a('                    NewAccessControl."User Security ID" := OldAccessControl."User Security ID";')
    a('                    NewAccessControl."Role ID" := NewRoleId;')
    a('                    NewAccessControl."Company Name" := OldAccessControl."Company Name";')
    a("                    NewAccessControl.Scope := OldAccessControl.Scope;")
    a('                    NewAccessControl."App ID" := NewAppId;')
    a("                    if NewAccessControl.Insert(true) then")
    a("                        Migrated += 1;")
    a("                end;")
    a("            until OldAccessControl.Next() = 0;")
    a("    end;")
    a("")
    a("    /// <summary>Copies BLOB fields, which DataTransfer does not support, row by row.</summary>")
    a("    local procedure CopyBlobFields(OldTableId: Integer; NewTableId: Integer; BlobFieldNos: List of [Integer])")
    a("    var")
    a('        TempBlob: Codeunit "Temp Blob";')
    a("        OldRef: RecordRef;")
    a("        NewRef: RecordRef;")
    a("        BlobField: FieldRef;")
    a("        BlobFieldNo: Integer;")
    a("        Modified: Boolean;")
    a("    begin")
    a("        OldRef.Open(OldTableId);")
    a("        NewRef.Open(NewTableId);")
    a("        if NewRef.FindSet(true) then")
    a("            repeat")
    a("                if FindMatchingRow(NewRef, OldRef) then begin")
    a("                    Modified := false;")
    a("                    foreach BlobFieldNo in BlobFieldNos do begin")
    a("                        BlobField := OldRef.Field(BlobFieldNo);")
    a("                        BlobField.CalcField();")
    a("                        Clear(TempBlob);")
    a("                        TempBlob.FromRecordRef(OldRef, BlobFieldNo);")
    a("                        if TempBlob.HasValue() then begin")
    a("                            TempBlob.ToRecordRef(NewRef, BlobFieldNo);")
    a("                            Modified := true;")
    a("                        end;")
    a("                    end;")
    a("                    if Modified then")
    a("                        NewRef.Modify(false);")
    a("                end;")
    a("            until NewRef.Next() = 0;")
    a("        NewRef.Close();")
    a("        OldRef.Close();")
    a("    end;")
    a("")
    a("    /// <summary>Finds the row in the old table that carries the same primary key values.</summary>")
    a("    local procedure FindMatchingRow(var NewRef: RecordRef; var OldRef: RecordRef): Boolean")
    a("    var")
    a("        NewKeyField: FieldRef;")
    a("        OldKeyField: FieldRef;")
    a("        NewKey: KeyRef;")
    a("        i: Integer;")
    a("    begin")
    a("        OldRef.Reset();")
    a("        NewKey := NewRef.KeyIndex(1);")
    a("        for i := 1 to NewKey.FieldCount() do begin")
    a("            NewKeyField := NewKey.FieldIndex(i);")
    a("            if not OldRef.FieldExist(NewKeyField.Number()) then")
    a("                exit(false);")
    a("            OldKeyField := OldRef.Field(NewKeyField.Number());")
    a("            OldKeyField.SetRange(NewKeyField.Value());")
    a("        end;")
    a("        exit(OldRef.FindFirst());")
    a("    end;")
    a("")
    a("    /// <summary>Shifts values that carried an object id or enum ordinal from an old range.</summary>")
    a("    local procedure ShiftIntegerField(TableId: Integer; FieldNo: Integer; FromValue: Integer; ToValue: Integer; Offset: Integer)")
    a("    var")
    a("        RecRef: RecordRef;")
    a("        TargetField: FieldRef;")
    a("        FieldValue: Integer;")
    a("    begin")
    a("        RecRef.Open(TableId);")
    a("        if RecRef.FindSet(true) then")
    a("            repeat")
    a("                TargetField := RecRef.Field(FieldNo);")
    a("                FieldValue := TargetField.Value();")
    a("                if (FieldValue >= FromValue) and (FieldValue <= ToValue) then begin")
    a("                    TargetField.Value(FieldValue + Offset);")
    a("                    RecRef.Modify(false);")
    a("                end;")
    a("            until RecRef.Next() = 0;")
    a("        RecRef.Close();")
    a("    end;")
    a("")
    a("    /// <summary>Reports whether the published app's table still exists in the database.</summary>")
    a("    local procedure OldTableExists(OldTableId: Integer): Boolean")
    a("    var")
    a('        TableMetadata: Record "Table Metadata";')
    a("    begin")
    a("        exit(TableMetadata.Get(OldTableId));")
    a("    end;")
    a("")
    a("    local procedure LogTakeOver(TableName: Text; RowCount: Integer)")
    a("    var")
    a("        Telemetry: Codeunit Telemetry;")
    a("        Dimensions: Dictionary of [Text, Text];")
    a("    begin")
    a("        Dimensions.Add('table', TableName);")
    a("        Dimensions.Add('rows', Format(RowCount, 0, 9));")
    a("        Telemetry.LogMessage(")
    a("            'ORI-BIF-0002', TakeOverTelemetryTxt, Verbosity::Normal,")
    a("            DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, Dimensions);")
    a("    end;")
    a("")
    a("    local procedure OldAppId(): Guid")
    a("    begin")
    a("        exit('%s');" % OLD_APP_ID)
    a("    end;")
    a("")
    a("    local procedure AppId(): Guid")
    a("    var")
    a("        AppInfo: ModuleInfo;")
    a("    begin")
    a("        NavApp.GetCurrentModuleInfo(AppInfo);")
    a("        exit(AppInfo.Id());")
    a("    end;")
    a("")
    a("    var")
    a("        TakeOverTelemetryTxt: Label 'Bifrost Nornir took data over from Origo Cloud Events Orchestrator.', Locked = true;")
    a("}")
    return "\n".join(L) + "\n", tables


def main():
    content, tables = gen()
    if ARGS.check:
        current = read(OUT) if os.path.exists(OUT) else ""
        if current != content:
            sys.exit("generated take-over codeunit is out of date - re-run gen_install.py")
        print("up to date")
        return
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "wb") as f:
        f.write(b"\xef\xbb\xbf" + content.encode("utf-8"))
    print("wrote", OUT)
    for name, old_name, old_id, new_id, fields in tables:
        copyable = [f for f in fields if not f[3] and not f[4]]
        blobs = [f for f in fields if f[4] and not f[3]]
        print("  %-26s %d -> %d  fields:%d blobs:%d" % (name, old_id, new_id, len(copyable), len(blobs)))
    print("  skipped (logs):", ", ".join(sorted(SKIP_TABLES)))


main()
