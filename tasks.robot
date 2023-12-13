*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.
...

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables
Library             OperatingSystem
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.RobotLogListener


*** Variables ***
${myclick}                      ${EMPTY}
${pdf}                          ${EMPTY}
${screenshot}                   ${EMPTY}
${GLOBAL_RETRY_AMOUNT}=         5x
${GLOBAL_RETRY_INTERVAL}=       10s


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Download the Excel file
    CSV to Table
    Create ZIP File
    Cleanup PDF directory


*** Keywords ***
Open the robot order website
    Open Chrome Browser    https://robotsparebinindustries.com/#/robot-order    maximized= ${True}
    Click Button When Visible    alias:Btnwarning

Download the Excel file
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True

Fill the form
    [Arguments]    ${fillorder}
    Select From List By Value    head    ${fillorder}[Head]
    Click Element    //*[@id="id-body-${fillorder}[Body]"]
    Input Text    css:input[placeholder="Enter the part number for the legs"]    ${fillorder}[Legs]
    Input Text    address    ${fillorder}[Address]

Preview the order
    Wait Until Element Is Visible    xpath://button[@id="preview" and @class="btn btn-secondary"]
    Click Element When Clickable    alias:Preview
    Wait Until Element Is Visible    xpath://button[@id="order" and @class="btn btn-primary"]
    Click Element When Clickable    alias:Order

Store the receipt as a PDF file
    [Arguments]    ${orderno}
    Wait Until Element Is Visible    id:receipt
    ${order_html} =    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${order_html}    ${OUTPUT_DIR}${/}output${/}Order_no_${orderno}.pdf
    RETURN    ${OUTPUT_DIR}${/}output${/}Order_no_${orderno}.pdf

Take a screenshot of the robot
    [Arguments]    ${orderno}
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}output${/}Order_no_${orderno}.png
    RETURN    ${OUTPUT_DIR}${/}output${/}Order_no_${orderno}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    ${files} =    Create List    ${screenshot}
    Open Pdf    ${pdf}
    Add Files To Pdf    ${files}    ${pdf}    append=${True}
    Close Pdf

CSV to Table
    ${orders} =    Read table from CSV    orders.csv
    FOR    ${ordr}    IN    @{orders}
        Log    ${ordr}
        Fill the form    ${ordr}
        Preview the order
        ${success} =    Is Element Visible    id:receipt
        WHILE    ${success} == ${False}    limit=10
            Log    Executed until the default loop limit (10) is hit.
            Wait Until Element Is Visible    xpath://button[@id="order" and @class="btn btn-primary"]
            Click Element When Clickable    alias:Order
            ${success} =    Is Element Visible    id:receipt
        END
        ${pdf} =    Store the receipt as a PDF file    ${ordr}[Order number]
        ${screenshot} =    Take a screenshot of the robot    ${ordr}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Click Element When Clickable    alias:Orderanother
        Click Button When Visible    alias:Btnwarning
    END

Create ZIP File
    ${zip_orders} =    Set Variable    ${OUTPUT_DIR}/PDFs.zip
    Archive Folder With Zip    ${OUTPUT_DIR}${/}output    ${zip_orders}

Cleanup PDF directory
    Remove Directory    ${OUTPUT_DIR}${/}output    True
