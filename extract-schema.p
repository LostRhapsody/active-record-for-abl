/*
 * Progress Schema Extraction Script for Active Record ABL
 * Extracts complete database schema to JSON format for Rust CLI processing
 */
message "executing extract schema".
DEFINE VARIABLE cOutputFile AS CHARACTER NO-UNDO INITIAL "schema.json".
DEFINE VARIABLE cJsonOutput AS LONGCHAR NO-UNDO.
DEFINE VARIABLE cTimestamp AS CHARACTER NO-UNDO.
DEFINE VARIABLE cTableJson AS CHARACTER NO-UNDO.
DEFINE VARIABLE cFieldJson AS CHARACTER NO-UNDO.
DEFINE VARIABLE cIndexJson AS CHARACTER NO-UNDO.
DEFINE VARIABLE cIndexFieldJson AS CHARACTER NO-UNDO.
DEFINE VARIABLE cDatabaseName AS CHARACTER NO-UNDO.
DEFINE VARIABLE cDatabaseVersion AS CHARACTER NO-UNDO.
DEFINE VARIABLE cCharacterSet AS CHARACTER NO-UNDO.
DEFINE VARIABLE lFirstFile AS LOGICAL NO-UNDO INITIAL TRUE.
DEFINE VARIABLE lFirstField AS LOGICAL NO-UNDO INITIAL TRUE.
DEFINE VARIABLE lFirstIndex AS LOGICAL NO-UNDO INITIAL TRUE.
DEFINE VARIABLE lFirstIndexField AS LOGICAL NO-UNDO INITIAL TRUE.
DEFINE VARIABLE cHelp AS CHARACTER NO-UNDO.
DEFINE VARIABLE cLabel AS CHARACTER NO-UNDO.
DEFINE VARIABLE cDesc AS CHARACTER NO-UNDO.
DEFINE VARIABLE cFormat AS CHARACTER NO-UNDO.

/* Helper function to escape JSON strings */
FUNCTION EscapeJsonString RETURNS CHARACTER (INPUT pcInput AS CHARACTER):
    DEFINE VARIABLE cResult AS CHARACTER NO-UNDO.
    DEFINE VARIABLE i AS INTEGER NO-UNDO.
    DEFINE VARIABLE cChar AS CHARACTER NO-UNDO.

    IF pcInput = ? THEN RETURN "".

    cResult = "".
    DO i = 1 TO LENGTH(pcInput):
        cChar = SUBSTRING(pcInput, i, 1).
        CASE cChar:
            WHEN '"' THEN cResult = cResult + '~\"'.
            WHEN '~\' THEN cResult = cResult + '~\~\'.
            WHEN CHR(10) THEN cResult = cResult + '~\n'.  /* Line feed */
            WHEN CHR(13) THEN cResult = cResult + '~\r'.  /* Carriage return */
            WHEN CHR(9) THEN cResult = cResult + '~\t'.   /* Tab */
            OTHERWISE cResult = cResult + cChar.
        END CASE.
    END.
    RETURN cResult.
END FUNCTION.

/* Get current timestamp */
ASSIGN cTimestamp = string(now).

/* Get database information */
ASSIGN
       cDatabaseName = LDBNAME("DICTDB")
       cDatabaseVersion = PROVERSION
       cCharacterSet = "iso8859-1". /* Default, could be enhanced to detect actual charset */

/* Start JSON output */
ASSIGN cJsonOutput = '~{"extracted_at":"' + cTimestamp + '",' +
                     '"database_info":~{"name":"' + cDatabaseName + '",' +
                     '"version":"' + cDatabaseVersion + '",' +
                     '"character_set":"' + cCharacterSet + '"~},' +
                     '"tables":[~n'.

/* Process each table */
FOR EACH _File WHERE _File._Hidden = NO
                 AND _File._File-name NE "?" NO-LOCK:

    cTableJson = "" .
    if not lFirstFile then
        cTableJson = cTableJson + ",".
    lFirstFile = false.

     cDesc = EscapeJsonString(_File._Desc).
     ASSIGN cTableJson = cTableJson + '~{"name":"' + _File._File-name + '",' +
                         '"description":"' + cDesc + '",' +
                         '"fields":[~n'.

    /* Process fields for this table */
    FOR EACH _Field OF _File NO-LOCK:
         cFieldJson = "".
         if not lFirstField then
             cFieldJson = ",".
         lFirstField = false.

         /* Escape all string fields */
         cHelp = EscapeJsonString(_Field._Help).
         cLabel = EscapeJsonString(_Field._Label).
         cFormat = EscapeJsonString(_Field._Format).

         ASSIGN cFieldJson = cFieldJson + '~{"name":"' + _Field._Field-Name + '",' +
                             '"data_type":"' + _Field._Data-Type + '",' +
                             '"extent":' + STRING(_Field._Extent) + ',' +
                             '"nullable":' + (IF _Field._Mandatory THEN "false" ELSE "true") + ',' +
                             '"initial":"' + EscapeJsonString(_Field._Initial) + '",' +
                             '"label":"' + cLabel + '",' +
                             '"format":"' + cFormat + '",' +
                             '"help":"' + cHelp + '"~}'.

        cTableJson = cTableJson + cFieldJson.
    END.

    lFirstField = true.

    ASSIGN cTableJson = cTableJson + '],"indexes":[~n'.

    /* Process indexes for this table */
    FOR EACH _Index WHERE _Index._File-Recid = RECID(_File)
                      AND _Index._Idx-Num > 0 NO-LOCK:
        cIndexJson = "".
        if not lFirstIndex then
            cIndexJson = ",".
        lFirstIndex = false.

        ASSIGN cIndexJson = cIndexJson + '~{"name":"' + _Index._Index-Name + '",' +
                            '"unique":' + (IF _Index._Unique THEN "true" ELSE "false") + ',' +
                            '"primary":' + (IF recid(_Index) eq _File._Prime-Index THEN "true" ELSE "false") + ',' +
                            '"active":' + (IF _Index._Active THEN "true" ELSE "false") + ',' +
                            '"fields":[~n'.

        /* Process index fields */
        FOR EACH _Index-Field OF _Index NO-LOCK,
            EACH _Field WHERE RECID(_Field) = _Index-Field._Field-Recid NO-LOCK:
            cIndexFieldJson = "".
            if not lFirstIndexField then
                cIndexFieldJson = ",".
            lFirstIndexField = false.

            ASSIGN cIndexFieldJson = cIndexFieldJson + '~{"name":"' + _Field._Field-Name + '",' +
                                    '"data_type":"' + _Field._Data-Type + '",' +
                                    '"abl_type":"' + _Field._Data-Type + '",' +
                                    '"ascending":' + (IF _Index-Field._Ascending THEN "true" ELSE "false") + '~}'.

            cIndexJson = cIndexJson + cIndexFieldJson.

        END. // for each indx field

        lFirstIndexField = true.

        ASSIGN cIndexJson = cIndexJson + ']~}~n'.
    END. // for each index

    lFirstIndex = true.

    ASSIGN cTableJson = cTableJson + ']~}~n'.

    cJsonOutput = cJsonOutput + cTableJson.

END. // for each table

ASSIGN cJsonOutput = cJsonOutput + ']~}~n'.

/* Write JSON to file */
OUTPUT TO VALUE(cOutputFile).
COPY-LOB FROM cJsonOutput TO FILE cOutputFile.
OUTPUT CLOSE.

MESSAGE "Schema extracted to " + cOutputFile VIEW-AS ALERT-BOX.
