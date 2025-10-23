/* Comprehensive OrderLine Active Record Test Script */
USING ara.*.

DEFINE VARIABLE order_line AS ara.OrderLine NO-UNDO.
DEFINE VARIABLE order_lines AS ara.OrderLine EXTENT NO-UNDO.
DEFINE VARIABLE i AS INTEGER NO-UNDO.
DEFINE VARIABLE found AS LOGICAL NO-UNDO.
DEFINE VARIABLE json_text AS CHARACTER NO-UNDO.

MESSAGE "=== OrderLine Active Record Test Suite ===" VIEW-AS ALERT-BOX.

/* Test 1: FindBy with CHARACTER field */
MESSAGE "Test 1: FindBy with order-number" VIEW-AS ALERT-BOX.
order_line = NEW ara.OrderLine().
found = order_line:FindBy("order-number", "W7769742").
IF found THEN DO:
    MESSAGE "Found order line: " + order_line:item-number + " - " + order_line:description VIEW-AS ALERT-BOX.
    json_text = order_line:ToJson():GetJsonText().
    MESSAGE "JSON: " + SUBSTRING(json_text, 1, 200) + "..." VIEW-AS ALERT-BOX.
END.
ELSE DO:
    MESSAGE "No order line found for W7769742" VIEW-AS ALERT-BOX.
END.

/* Test 2: FindBy with INTEGER field */
MESSAGE "Test 2: FindBy with line-number" VIEW-AS ALERT-BOX.
order_line = NEW ara.OrderLine().
found = order_line:FindBy("line-number", 1).
IF found THEN DO:
    MESSAGE "Found line 1: " + order_line:order-number + " - " + order_line:item-number VIEW-AS ALERT-BOX.
END.
ELSE DO:
    MESSAGE "No line 1 found" VIEW-AS ALERT-BOX.
END.

/* Test 3: FindBy with DECIMAL field */
MESSAGE "Test 3: FindBy with price" VIEW-AS ALERT-BOX.
order_line = NEW ara.OrderLine().
found = order_line:FindBy("price", 25.99).
IF found THEN DO:
    MESSAGE "Found item with price 25.99: " + order_line:item-number VIEW-AS ALERT-BOX.
END.
ELSE DO:
    MESSAGE "No item found with price 25.99" VIEW-AS ALERT-BOX.
END.

/* Test 4: FindBy with LOGICAL field */
MESSAGE "Test 4: FindBy with gift_item" VIEW-AS ALERT-BOX.
order_line = NEW ara.OrderLine().
found = order_line:FindBy("gift_item", TRUE).
IF found THEN DO:
    MESSAGE "Found gift item: " + order_line:item-number VIEW-AS ALERT-BOX.
END.
ELSE DO:
    MESSAGE "No gift items found" VIEW-AS ALERT-BOX.
END.

/* Test 5: FindBy with DATE field */
MESSAGE "Test 5: FindBy with order-date" VIEW-AS ALERT-BOX.
order_line = NEW ara.OrderLine().
found = order_line:FindBy("order-date", TODAY).
IF found THEN DO:
    MESSAGE "Found order from today: " + order_line:order-number VIEW-AS ALERT-BOX.
END.
ELSE DO:
    MESSAGE "No orders found for today" VIEW-AS ALERT-BOX.
END.

/* Test 6: FindBy with extent fields */
MESSAGE "Test 6: FindBy with extent fields" VIEW-AS ALERT-BOX.
order_line = NEW ara.OrderLine().
found = order_line:FindBy("invoice-comment", 1, "Special handling required").
IF found THEN DO:
    MESSAGE "Found order with special comment: " + order_line:order-number VIEW-AS ALERT-BOX.
END.
ELSE DO:
    MESSAGE "No orders found with special comment" VIEW-AS ALERT-BOX.
END.

/* Test 7: First and Last methods */
MESSAGE "Test 7: First and Last methods" VIEW-AS ALERT-BOX.
order_line = NEW ara.OrderLine().
found = order_line:First().
IF found THEN DO:
    MESSAGE "First order line: " + order_line:order-number + " - " + order_line:item-number VIEW-AS ALERT-BOX.
END.

order_line = NEW ara.OrderLine().
found = order_line:Last().
IF found THEN DO:
    MESSAGE "Last order line: " + order_line:order-number + " - " + order_line:item-number VIEW-AS ALERT-BOX.
END.

/* Show first few records */
DO i = 1 TO MINIMUM(3, EXTENT(order_lines)):
    IF order_lines[i] <> ? THEN DO:
        MESSAGE "Order Line " + STRING(i) + ": " + order_lines[i]:order-number + " - " + order_lines[i]:item-number VIEW-AS ALERT-BOX.
    END.
END.

/* Test 9: Where method with simple condition */
MESSAGE "Test 9: Where method" VIEW-AS ALERT-BOX.
order_line = NEW ara.OrderLine().
order_lines = order_line:Where("order-number = 'W7769742'").
MESSAGE "Orders matching W7769742: " + STRING(EXTENT(order_lines)) VIEW-AS ALERT-BOX.

/* Test 10: Where method with complex condition */
order_lines = order_line:Where("price > 100 AND gift_item = TRUE").
MESSAGE "Expensive gift items: " + STRING(EXTENT(order_lines)) VIEW-AS ALERT-BOX.

/* Test 11: Create new record */
MESSAGE "Test 11: Create new record" VIEW-AS ALERT-BOX.
order_line = NEW ara.OrderLine().
order_line:order-number = "TEST001".
order_line:line-number = 1.
order_line:item-number = "TEST-ITEM".
order_line:description = "Test Item Description".
order_line:price = 99.99.
order_line:order-qty = 1.
order_line:company = "TEST".
order_line:order-date = TODAY.
order_line:order-type = "S".

found = order_line:Save().
IF found THEN DO:
    MESSAGE "Created new test order line successfully" VIEW-AS ALERT-BOX.
    
    /* Test 12: Update the record */
    MESSAGE "Test 12: Update record" VIEW-AS ALERT-BOX.
    found = order_line:Update("description", "Updated Test Description").
    IF found THEN DO:
        MESSAGE "Updated description successfully" VIEW-AS ALERT-BOX.
    END.
    
    found = order_line:Update("price", 149.99).
    IF found THEN DO:
        MESSAGE "Updated price successfully" VIEW-AS ALERT-BOX.
    END.
    
    /* Test 13: Update extent fields */
    MESSAGE "Test 13: Update extent fields" VIEW-AS ALERT-BOX.
    found = order_line:Update("note", 1, "First note").
    IF found THEN DO:
        MESSAGE "Updated note[1] successfully" VIEW-AS ALERT-BOX.
    END.
    
    found = order_line:Update("note", 2, "Second note").
    IF found THEN DO:
        MESSAGE "Updated note[2] successfully" VIEW-AS ALERT-BOX.
    END.
    
    /* Test 14: Find the updated record */
    MESSAGE "Test 14: Find updated record" VIEW-AS ALERT-BOX.
    order_line = NEW ara.OrderLine().
    found = order_line:FindBy("order-number", "TEST001").
    IF found THEN DO:
        MESSAGE "Found updated record: " + order_line:description + " - Price: " + STRING(order_line:price) VIEW-AS ALERT-BOX.
        MESSAGE "Note[1]: " + order_line:note[1] + " - Note[2]: " + order_line:note[2] VIEW-AS ALERT-BOX.
    END.
    
    /* Test 15: Destroy the record */
    MESSAGE "Test 15: Destroy record" VIEW-AS ALERT-BOX.
    found = order_line:Destroy().
    IF found THEN DO:
        MESSAGE "Destroyed test record successfully" VIEW-AS ALERT-BOX.
    END.
    
    /* Verify it's gone */
    order_line = NEW ara.OrderLine().
    found = order_line:FindBy("order-number", "TEST001").
    IF NOT found THEN DO:
        MESSAGE "Confirmed: Test record no longer exists" VIEW-AS ALERT-BOX.
    END.
END.
ELSE DO:
    MESSAGE "Failed to create test order line" VIEW-AS ALERT-BOX.
END.

/* Test 16: Error handling */
MESSAGE "Test 16: Error handling" VIEW-AS ALERT-BOX.
order_line = NEW ara.OrderLine().
found = order_line:Update("nonexistent-field", "value").
IF NOT found THEN DO:
    MESSAGE "Correctly handled invalid field name" VIEW-AS ALERT-BOX.
END.

/* Test 17: JSON serialization with extent fields */
MESSAGE "Test 17: JSON with extent fields" VIEW-AS ALERT-BOX.
order_line = NEW ara.OrderLine().
found = order_line:First().
IF found THEN DO:
    /* Set some extent values for testing */
    order_line:note[1] = "Test note 1".
    order_line:note[2] = "Test note 2".
    order_line:alt-comm-amount[1] = 5.50.
    order_line:alt-comm-amount[2] = 10.25.
    
    json_text = order_line:ToJson():GetJsonText().
    MESSAGE "JSON with extents: " + SUBSTRING(json_text, 1, 300) + "..." VIEW-AS ALERT-BOX.
END.

/* Test 18: XML serialization */
MESSAGE "Test 18: XML serialization" VIEW-AS ALERT-BOX.
IF found THEN DO:
    DEFINE VARIABLE xml_text AS LONGCHAR NO-UNDO.
    xml_text = order_line:ToXml().
    MESSAGE "XML length: " + STRING(LENGTH(xml_text)) + " characters" VIEW-AS ALERT-BOX.
END.

/* Test 19: Temp-table serialization */
MESSAGE "Test 19: Temp-table serialization" VIEW-AS ALERT-BOX.
IF found THEN DO:
    DEFINE VARIABLE hTT AS HANDLE NO-UNDO.
    hTT = order_line:ToTempTable().
    MESSAGE "Temp-table created with " + STRING(hTT:NUM-ROWS) + " rows" VIEW-AS ALERT-BOX.
    DELETE OBJECT hTT.
END.

MESSAGE "=== All tests completed ===" VIEW-AS ALERT-BOX.
