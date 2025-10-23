/*
Deprecated warning
This script is deprecated and just here for reference
Script: generate_orm.p
*/
DEFINE VARIABLE cOutputDir  AS CHARACTER NO-UNDO INITIAL "orm/".
DEFINE VARIABLE cTypeDir    AS CHARACTER NO-UNDO INITIAL "orm/types/".
// DEFINE VARIABLE cOutputDir  AS CHARACTER NO-UNDO INITIAL "/psc/dlc/src/fdm4/orm/".
DEFINE VARIABLE cTableName  AS CHARACTER NO-UNDO INITIAL "Customer".
DEFINE VARIABLE iLimit      AS INTEGER   NO-UNDO INITIAL 1.
DEFINE VARIABLE lFileExists AS LOGICAL   NO-UNDO.
DEFINE VARIABLE iCount      AS INTEGER   NO-UNDO INITIAL 0.

/* Helper function get current timestamp in yyyy-mm-dd format */
FUNCTION Get-Timestamp RETURNS CHARACTER ():
    DEFINE VARIABLE cTimestamp AS CHARACTER NO-UNDO.
    ASSIGN cTimestamp = STRING(TODAY, "9999-99-99").
    RETURN cTimestamp.
END FUNCTION.

/* Helper function to map OpenEdge data types to ABL with prefix */
FUNCTION MAP-DATA-TYPE RETURNS CHARACTER (cType AS CHARACTER, OUTPUT cPrefix AS CHARACTER):
    CASE cType:
        WHEN "BLOB" THEN DO: ASSIGN cPrefix = "b_". RETURN "RAW". END.
        WHEN "CHARACTER" THEN DO: ASSIGN cPrefix = "c_". RETURN "CHARACTER". END.
        WHEN "CLOB" THEN DO: ASSIGN cPrefix = "cl_". RETURN "LONGCHAR". END.
        WHEN "DATE" THEN DO: ASSIGN cPrefix = "d_". RETURN "DATE". END.
        WHEN "DATETIME" THEN DO: ASSIGN cPrefix = "dt_". RETURN "DATETIME". END.
        WHEN "DATETIME-TZ" THEN DO: ASSIGN cPrefix = "dttz_". RETURN "DATETIME-TZ". END.
        WHEN "DECIMAL" THEN DO: ASSIGN cPrefix = "dec_". RETURN "DECIMAL". END.
        WHEN "INTEGER" THEN DO: ASSIGN cPrefix = "i_". RETURN "INTEGER". END.
        WHEN "INT64" THEN DO: ASSIGN cPrefix = "i64_". RETURN "INT64". END.
        WHEN "LOGICAL" THEN DO: ASSIGN cPrefix = "l_". RETURN "LOGICAL". END.
        WHEN "RECID" THEN DO: ASSIGN cPrefix = "r_". RETURN "INTEGER". END.
        WHEN "RAW" THEN DO: ASSIGN cPrefix = "raw_". RETURN "RAW". END.
        OTHERWISE DO: ASSIGN cPrefix = "c_". RETURN "CHARACTER". END. /* Fallback */
    END CASE.
END FUNCTION.

/* Helper function to retrieve indexes for a table */
FUNCTION Get-Indexes-For-Table RETURNS CHARACTER (INPUT pcTable AS CHARACTER):
    DEFINE VARIABLE cIndexList AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cIndexEntry AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cPrefix AS CHARACTER NO-UNDO.

    FOR EACH _Index WHERE _Index._File-Recid = RECID(_File) AND _Index._Idx-Num > 0 NO-LOCK:
        ASSIGN cIndexEntry = _Index._Index-Name + "|".
        FOR EACH _Index-Field OF _Index NO-LOCK,
            EACH _Field WHERE RECID(_Field) = _Index-Field._Field-Recid NO-LOCK
            BY _Index-Field._Index-Seq:
            ASSIGN cIndexEntry = cIndexEntry + _Field._Field-Name + "," + MAP-DATA-TYPE(_Field._Data-Type, cPrefix) + ";".
        END.
        ASSIGN cIndexEntry = TRIM(cIndexEntry, ";")
               cIndexList = cIndexList + (IF cIndexList = "" THEN "" ELSE CHR(1)) + cIndexEntry.
    END.
    RETURN cIndexList.
END FUNCTION.

/* Helper function to check schema against existing class */
FUNCTION Check-Schema-Match RETURNS LOGICAL (INPUT pcFilePath AS CHARACTER):
    DEFINE VARIABLE cLine AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cPropDef AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cFieldList AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cExistingFields AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cPrefix AS CHARACTER NO-UNDO.

    FOR EACH _Field OF _File NO-LOCK:
        ASSIGN cPropDef = "DEFINE PUBLIC PROPERTY " + _Field._Field-Name + " AS " +
                          MAP-DATA-TYPE(_Field._Data-Type, cPrefix) +
                          (IF _Field._Extent > 0 THEN " EXTENT " + STRING(_Field._Extent) ELSE "") +
                          " GET. SET."
               cFieldList = cFieldList + (IF cFieldList eq "" THEN "" ELSE CHR(1)) + cPropDef.
    END.

    INPUT FROM VALUE(pcFilePath).
    REPEAT:
        IMPORT UNFORMATTED cLine.
        IF cLine BEGINS "  DEFINE PUBLIC PROPERTY" AND
           NOT cLine MATCHES "*ROWID_*" AND
           NOT cLine MATCHES "*TEMP-TABLE*" THEN
            ASSIGN cExistingFields = cExistingFields + (IF cExistingFields = "" THEN "" ELSE CHR(1)) + TRIM(cLine).
    END.
    INPUT CLOSE.

    RETURN cFieldList eq cExistingFields.
END FUNCTION.

/* Ensure output directories exist */
OS-CREATE-DIR VALUE(cOutputDir).
OS-CREATE-DIR VALUE(cTypeDir).

/* Process tables */
FOR EACH _File WHERE _File._Hidden = NO
                 AND _File._File-name NE "?" NO-LOCK:

    ASSIGN cTableName = _File._File-name
           lFileExists = SEARCH(cOutputDir + cTableName + ".cls") <> ?.

    IF iCount >= iLimit THEN NEXT.

    IF lFileExists AND Check-Schema-Match(cOutputDir + cTableName + ".cls") THEN
        NEXT.

    if cTableName ne "order-line" then next.

   //  MESSAGE "Generating or updating class for table: " + cTableName VIEW-AS ALERT-BOX.

    /* Generate type classes for index fields */
    DEFINE VARIABLE cIndexes AS CHARACTER NO-UNDO.
    DEFINE VARIABLE iIndex AS INTEGER NO-UNDO.
    DEFINE VARIABLE cIndexEntry AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cFields AS CHARACTER NO-UNDO.
    DEFINE VARIABLE iField AS INTEGER NO-UNDO.
    DEFINE VARIABLE cFieldName AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cFieldType AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cTypePrefix AS CHARACTER NO-UNDO.

    ASSIGN cIndexes = Get-Indexes-For-Table(cTableName).
    DO iIndex = 1 TO NUM-ENTRIES(cIndexes, CHR(1)):
        ASSIGN cIndexEntry = ENTRY(iIndex, cIndexes, CHR(1))
               cFields = ENTRY(2, cIndexEntry, "|").
        DO iField = 1 TO NUM-ENTRIES(cFields, ";"):
            ASSIGN cFieldName = ENTRY(1, ENTRY(iField, cFields, ";"), ",")
                   cFieldType = ENTRY(2, ENTRY(iField, cFields, ";"), ",").
            cFieldType = MAP-DATA-TYPE(cFieldType, cTypePrefix). /* Get prefix */
            IF SEARCH(cTypeDir + cTypePrefix + cFieldName + ".cls") = ? THEN DO:
                OUTPUT TO VALUE(cTypeDir + cTypePrefix + cFieldName + ".cls").
                PUT UNFORMATTED "CLASS orm.types." + cTypePrefix + cFieldName + ":" SKIP
                               "  DEFINE PUBLIC PROPERTY Value AS " + cFieldType + " GET. SET." SKIP
                               "  CONSTRUCTOR PUBLIC " + cTypePrefix + cFieldName + "(INPUT pValue AS " + cFieldType + "):" SKIP
                               "    THIS-OBJECT:Value = pValue." SKIP
                               "  END CONSTRUCTOR." SKIP
                               "END CLASS." SKIP.
                OUTPUT CLOSE.
                COMPILE VALUE(cTypeDir + cTypePrefix + cFieldName + ".cls") SAVE.
            END.
        END.
    END.

    /* Generate or update class */
    OUTPUT TO VALUE(cOutputDir + cTableName + ".cls").
    PUT UNFORMATTED "/* WARNING: This is an auto-generated file. Do NOT add custom logic here as it will be overwritten on schema update." SKIP
                   " * Extend this class in a separate file to add custom methods (e.g., for loading related records). " SKIP
                   " * Generated on: " + Get-Timestamp() + " with generate_orm.p v1.0 */" SKIP
                   "CLASS orm." + cTableName + ":" SKIP.

    /* Define properties dynamically from schema with extent support */
    FOR EACH _Field OF _File NO-LOCK:
        PUT UNFORMATTED "  DEFINE PUBLIC PROPERTY " + _Field._Field-Name + " AS " +
                        MAP-DATA-TYPE(_Field._Data-Type, cTypePrefix) +
                        (IF _Field._Extent > 0 THEN " EXTENT " + STRING(_Field._Extent) ELSE "") +
                        " GET. SET." SKIP.
    END.

    PUT UNFORMATTED "  DEFINE PUBLIC PROPERTY ROWID_ AS ROWID GET. SET." SKIP.
    PUT UNFORMATTED "  DEFINE PRIVATE TEMP-TABLE tt" + cTableName + " LIKE " + cTableName + "." SKIP.
    PUT UNFORMATTED "  DEFINE PROTECTED PROPERTY DebugEnabled AS LOGICAL INITIAL FALSE GET. SET." SKIP
                   "  DEFINE PROTECTED PROPERTY LogFile AS CHARACTER INITIAL '' GET. SET." SKIP.

    /* Logging/Debugging Hook */
    PUT UNFORMATTED "  /* Log action for debugging or file logging */" SKIP
                   "  METHOD PROTECTED VOID LogAction(INPUT pcAction AS CHARACTER):" SKIP
                   "    IF THIS-OBJECT:DebugEnabled THEN" SKIP
                   "      MESSAGE pcAction VIEW-AS ALERT-BOX." SKIP
                   "    IF THIS-OBJECT:LogFile <> '' THEN DO:" SKIP
                   "      OUTPUT TO VALUE(THIS-OBJECT:LogFile) APPEND." SKIP
                   "      PUT UNFORMATTED pcAction SKIP(1)." SKIP
                   "      OUTPUT CLOSE." SKIP
                   "    END." SKIP
                   "  END METHOD." SKIP.

    /* CRUD Methods */
    PUT UNFORMATTED "  /* Create or Update - Auto-generated, do not modify */" SKIP
                   "  METHOD PUBLIC VOID Save():" SKIP
                   "    DEFINE BUFFER buf" + cTableName + " FOR " + cTableName + "." SKIP
                   "    DO TRANSACTION ON ERROR UNDO, THROW:" SKIP
                   "      IF THIS-OBJECT:ROWID_ <> ? THEN DO:" SKIP
                   "       FIND FIRST buf" + cTableName + " WHERE ROWID(buf" + cTableName + ") = THIS-OBJECT:ROWID_ EXCLUSIVE-LOCK NO-ERROR." SKIP
                   "        LogAction('Saving existing record ROWID ' + STRING(THIS-OBJECT:ROWID_))." SKIP
                   "      END." SKIP
                   "      IF NOT AVAILABLE buf" + cTableName + " THEN DO:" SKIP
                   "        CREATE buf" + cTableName + "." SKIP
                   "        LogAction('Creating new record')." SKIP
                   "      END." SKIP
                   "      ASSIGN" SKIP.
    FOR EACH _Field OF _File NO-LOCK:
        PUT UNFORMATTED "        buf" + cTableName + "." + _Field._Field-Name +
                        " = THIS-OBJECT:" + _Field._Field-Name SKIP.
    END.
    PUT UNFORMATTED "        THIS-OBJECT:ROWID_ = ROWID(buf" + cTableName + ")" SKIP
                   "      ." SKIP
                   "    END." SKIP
                   "    CATCH eError AS Progress.Lang.Error:" SKIP
                   "      LogAction('Error in Save: ' + eError:GetMessage(1))." SKIP
                   "      MESSAGE 'Error in Save method for " + cTableName + ": ' + eError:GetMessage(1)." SKIP
                   "      UNDO, THROW eError." SKIP
                   "    END CATCH." SKIP
                   "  END METHOD." SKIP
                   SKIP
                   "  /* Read by ROWID - Auto-generated, do not modify */" SKIP
                   "  METHOD PUBLIC LOGICAL Load(INPUT prRowId AS ROWID):" SKIP
                   "    DEFINE BUFFER buf" + cTableName + " FOR " + cTableName + "." SKIP
                   "    LogAction('Loading record by ROWID ' + STRING(prRowId))." SKIP
                   "    FIND FIRST buf" + cTableName + " WHERE ROWID(buf" + cTableName + ") = prRowId NO-LOCK NO-ERROR." SKIP
                   "    IF AVAILABLE buf" + cTableName + " THEN DO:" SKIP
                   "      LoadFields(BUFFER buf" + cTableName + ")." SKIP
                   "      THIS-OBJECT:ROWID_ = ROWID(buf" + cTableName + ")." SKIP
                   "      LoadRelatedRecords(BUFFER buf" + cTableName + ")." SKIP
                   "      RETURN TRUE." SKIP
                   "    END." SKIP
                   "    RETURN FALSE." SKIP
                   "  END METHOD." SKIP.

    /* Generate overloaded Load methods for each index */
    ASSIGN cIndexes = Get-Indexes-For-Table(cTableName).
    DO iIndex = 1 TO NUM-ENTRIES(cIndexes, CHR(1)):
        ASSIGN cIndexEntry = ENTRY(iIndex, cIndexes, CHR(1))
               cFields = ENTRY(2, cIndexEntry, "|")
               cIndexEntry = ENTRY(1, cIndexEntry, "|").
        PUT UNFORMATTED "  /* Read by index " + cIndexEntry + " - Auto-generated, do not modify */" SKIP
                       "  METHOD PUBLIC LOGICAL Load(".
        DO iField = 1 TO NUM-ENTRIES(cFields, ";"):
            ASSIGN cFieldName = ENTRY(1, ENTRY(iField, cFields, ";"), ",")
                   cFieldType = ENTRY(2, ENTRY(iField, cFields, ";"), ",").
            cFieldType = MAP-DATA-TYPE(cFieldType, cTypePrefix).
            PUT UNFORMATTED "INPUT p" + cFieldName + " AS orm.types." + cTypePrefix + cFieldName +
                            (IF iField lt NUM-ENTRIES(cFields, ";") THEN ", " ELSE "").
        END.
        PUT UNFORMATTED "):" SKIP
                       "    DEFINE BUFFER buf" + cTableName + " FOR " + cTableName + "." SKIP
                       "    LogAction('Loading record by index " + cIndexEntry + "')." SKIP
                       "    FIND FIRST buf" + cTableName + " WHERE ".
        DO iField = 1 TO NUM-ENTRIES(cFields, ";"):
            ASSIGN cFieldName = ENTRY(1, ENTRY(iField, cFields, ";"), ",").
            PUT UNFORMATTED "buf" + cTableName + "." + cFieldName + " = p" + cFieldName + ":Value" +
                            (IF iField < NUM-ENTRIES(cFields, ";") THEN " AND " ELSE "").
        END.
        PUT UNFORMATTED " NO-LOCK NO-ERROR." SKIP
                       "    IF AVAILABLE buf" + cTableName + " THEN DO:" SKIP
                       "      LoadFields(BUFFER buf" + cTableName + ")." SKIP
                       "      THIS-OBJECT:ROWID_ = ROWID(buf" + cTableName + ")." SKIP
                       "      LoadRelatedRecords(BUFFER buf" + cTableName + ")." SKIP
                       "      RETURN TRUE." SKIP
                       "    END." SKIP
                       "    RETURN FALSE." SKIP
                       "  END METHOD." SKIP.
    END.

    /* LoadBatch Method */
    PUT UNFORMATTED "  /* Batch Load - Auto-generated, do not modify */" SKIP
                   "  METHOD PUBLIC orm." + cTableName + " EXTENT LoadBatch(INPUT pcWhere AS CHARACTER):" SKIP
                   "    DEFINE VARIABLE oRecords AS orm." + cTableName + " EXTENT NO-UNDO." SKIP
                   "    DEFINE VARIABLE iCount AS INTEGER NO-UNDO INITIAL 0." SKIP
                   "    DEFINE VARIABLE queryString AS CHAR NO-UNDO." SKIP
                   "    DEFINE VARIABLE qh" + cTableName + " AS HANDLE NO-UNDO." SKIP
                   "    DEFINE QUERY q" + cTableName + " FOR " + cTableName + "." SKIP
                   "    queryString = 'FOR EACH " + cTableName + " WHERE ' + pcWhere + ' NO-LOCK'." SKIP
                   "    QUERY q" + cTableName + ":QUERY-PREPARE(queryString)." SKIP
                   "    QUERY q" + cTableName + ":QUERY-OPEN()." SKIP
                   "    qh" + cTableName + " = QUERY q" + cTableName + ":HANDLE." SKIP
                   "    LogAction('Loading batch with WHERE: ' + pcWhere)." SKIP
                   "    DO WHILE qh" + cTableName + ":GET-NEXT():" SKIP
                   "      iCount = iCount + 1." SKIP
                   "      EXTENT(oRecords) = iCount." SKIP
                   "      oRecords[iCount] = NEW orm." + cTableName + "()." SKIP
                   "      oRecords[iCount]:LoadFields(BUFFER " + cTableName + ")." SKIP
                   "      oRecords[iCount]:ROWID_ = ROWID(" + cTableName + ")." SKIP
                   "      oRecords[iCount]:LoadRelatedRecords(BUFFER " + cTableName + ")." SKIP
                   "    END." SKIP
                   "    RETURN oRecords." SKIP
                   "  END METHOD." SKIP.

    PUT UNFORMATTED SKIP
                   "  /* Delete - Auto-generated, do not modify */" SKIP
                   "  METHOD PUBLIC VOID Delete():" SKIP
                   "    DEFINE BUFFER buf" + cTableName + " FOR " + cTableName + "." SKIP
                   "    DO TRANSACTION ON ERROR UNDO, THROW:" SKIP
                   "      IF THIS-OBJECT:ROWID_ <> ? THEN DO:" SKIP
                   "        FIND FIRST buf" + cTableName + " WHERE ROWID(buf" + cTableName + ") = THIS-OBJECT:ROWID_ EXCLUSIVE-LOCK NO-ERROR." SKIP
                   "        LogAction('Deleting record ROWID ' + STRING(THIS-OBJECT:ROWID_))." SKIP
                   "        IF AVAILABLE buf" + cTableName + " THEN DO:" SKIP
                   "          DELETE buf" + cTableName + "." SKIP
                   "          THIS-OBJECT:ROWID_ = ?." SKIP
                   "        END." SKIP
                   "      END." SKIP
                   "    END." SKIP
                   "    CATCH eError AS Progress.Lang.Error:" SKIP
                   "      LogAction('Error in Delete: ' + eError:GetMessage(1))." SKIP
                   "      MESSAGE 'Error in Save method for " + cTableName + ": ' + eError:GetMessage(1)." SKIP
                   "      UNDO, THROW eError." SKIP
                   "    END CATCH." SKIP
                   "  END METHOD." SKIP
                   SKIP
                   "  /* Load Fields Into Object - Auto-generated, do not modify */" SKIP
                   "  METHOD PRIVATE VOID LoadFields(BUFFER buf" + cTableName + " FOR " + cTableName + "):" SKIP
                   "    ASSIGN" SKIP.
    FOR EACH _Field OF _File NO-LOCK:
        PUT UNFORMATTED "      THIS-OBJECT:" + _Field._Field-Name +
                        " = buf" + cTableName + "." + _Field._Field-Name SKIP.
    END.
    PUT UNFORMATTED "    ." SKIP
                   "  END METHOD." SKIP
                   SKIP
                   "  /* Hook for loading related records - Override in child class */" SKIP
                   "  METHOD PROTECTED VOID LoadRelatedRecords(BUFFER buf" + cTableName + " FOR " + cTableName + "):" SKIP
                   "    /* Override this method in a child class to load related records." SKIP
                   "     * Example: For an Order, load OrderLines into an array or implement an iterator like GetNextOrderLine()." SKIP
                   "     * Use buf" + cTableName + " to access the current record’s fields (e.g., OrderNum). */" SKIP
                   "  END METHOD." SKIP
                   SKIP
                   "  /* Serialize to Temp-Table - Auto-generated, do not modify */" SKIP
                   "  METHOD PUBLIC HANDLE ToTempTable():" SKIP
                   "    DEFINE BUFFER bufTT FOR tt" + cTableName + "." SKIP
                   "    CREATE bufTT." SKIP
                   "    ASSIGN" SKIP.
    FOR EACH _Field OF _File NO-LOCK:
        PUT UNFORMATTED "      bufTT." + _Field._Field-Name +
                        " = THIS-OBJECT:" + _Field._Field-Name SKIP.
    END.
    PUT UNFORMATTED "    ." SKIP
                   "    RETURN TEMP-TABLE tt" + cTableName + ":HANDLE." SKIP
                   "  END METHOD." SKIP
                   SKIP
                   "  /* Serialize to JSON - Auto-generated, do not modify */" SKIP
                   "  METHOD PUBLIC Progress.Json.ObjectModel.JsonObject ToJson():" SKIP
                   "    DEFINE VARIABLE oJson AS Progress.Json.ObjectModel.JsonObject NO-UNDO." SKIP
                   "    oJson = NEW Progress.Json.ObjectModel.JsonObject()." SKIP
                   "    DEFINE VARIABLE i AS INTEGER NO-UNDO." SKIP
                   "    DEFINE VARIABLE ja AS Progress.Json.ObjectModel.JsonArray NO-UNDO." SKIP.
    FOR EACH _Field OF _File NO-LOCK:
        IF _Field._Extent > 0 THEN DO:
            PUT UNFORMATTED "    ja = NEW Progress.Json.ObjectModel.JsonArray()." SKIP
                           "    DO i = 1 TO " + STRING(_Field._Extent) + ":" SKIP
                           "      ja:Add(THIS-OBJECT:" + _Field._Field-Name + "[i])." SKIP
                           "    END." SKIP
                           "    oJson:Add('" + _Field._Field-Name + "', ja)." SKIP.
        END.
        ELSE DO:
            PUT UNFORMATTED "    oJson:Add('" + _Field._Field-Name + "', THIS-OBJECT:" + _Field._Field-Name + ")." SKIP.
        END.
    END.
    PUT UNFORMATTED "    oJson:Add('ROWID_', STRING(THIS-OBJECT:ROWID_))." SKIP
                   "    RETURN oJson." SKIP
                   "  END METHOD." SKIP
                   SKIP
                   "  /* Serialize to XML - Auto-generated, do not modify */" SKIP
                   "  METHOD PUBLIC LONGCHAR ToXml():" SKIP
                   "    DEFINE VARIABLE hTT AS HANDLE NO-UNDO." SKIP
                   "    DEFINE VARIABLE lcXml AS LONGCHAR NO-UNDO." SKIP
                   "    hTT = ToTempTable()." SKIP
                   "    hTT:WRITE-XML('LONGCHAR', lcXml, TRUE)." SKIP
                   "    DELETE OBJECT hTT." SKIP
                   "    RETURN lcXml." SKIP
                   "  END METHOD." SKIP
                   SKIP
                   "  /* Constructor - Auto-generated, do not modify */" SKIP
                   "  CONSTRUCTOR PUBLIC " + cTableName + "():" SKIP
                   "    THIS-OBJECT:ROWID_ = ?." SKIP
                   "  END CONSTRUCTOR." SKIP
                   "  /* Destructor - Auto-generated, do not modify */" SKIP
                   "  DESTRUCTOR PUBLIC " + cTableName + "():" SKIP
                   "  END DESTRUCTOR." SKIP.

    PUT UNFORMATTED "END CLASS." SKIP.
    OUTPUT CLOSE.

    COMPILE VALUE(cOutputDir + cTableName + ".cls") SAVE NO-ERROR.
    IF COMPILER:ERROR THEN DO:
        MESSAGE "Compilation failed for " + cTableName + ": " + COMPILER:get-message(1) VIEW-AS ALERT-BOX ERROR.
    END.

    ASSIGN iCount = iCount + 1.
END.

MESSAGE "Generated and compiled " + STRING(iCount) + " new or updated class(es)" VIEW-AS ALERT-BOX.
