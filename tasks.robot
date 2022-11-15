*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images

Library             RPA.Browser.Selenium    auto_close=${False}
Library             RPA.PDF
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.Archive
Library             RPA.Dialogs
Library             RPA.Robocloud.Secrets


*** Variables ***
${ORDERS_FILE_NAME}=    orders.csv
${PDF_RECEIPTS_DIR}=    ${OUTPUT_DIR}${/}receipts
${ROBOT_IMAGES_DIR}=    ${OUTPUT_DIR}${/}robotImages
${DOWNLOAD_DIR}=        ${OUTPUT_DIR}${/}downloads


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order page URL
    ${orders}=    Read orders from csv file
    FOR    ${order}    IN    @{orders}
        Agree the terms of use
        Fill up the order details    ${order}
        Preview the robot order
        Wait Until Keyword Succeeds
        ...    3x
        ...    0.5s
        ...    Place the order
        ${pdf_receipt}=    Save the order HTML receipt as a PDF file    ${order}[Order number]
        ${robot_preview_img}=    Screenshot robot preview image    ${order}[Order number]
        Embed robot preview image to the PDF receipt    ${robot_preview_img}    ${pdf_receipt}
        Go to order another robot
    END
    Create ZIP Archive of the receipts
    Success Dialog
    [Teardown]    Close Browser


*** Keywords ***
Open the robot order page URL
    ${urls}=    Get Secret    urls
    Open Available Browser    ${urls}[order_page_url]

Agree the terms of use
    Click Button    css:button.btn-dark
    Wait Until Page Contains Element    xpath://*[@id="root"]/div/div[1]/div/div[1]/form

Collect the URL of the orders CSV file from user
    Add text input    URL    label=Orders File URL
    ${response}=    Run dialog
    RETURN    ${response.URL}

Download the Orders CSV file
    [Arguments]    ${ORDERS_FILE_URL}
    Download    ${ORDERS_FILE_URL}
    ...    target_file=${DOWNLOAD_DIR}${/}${ORDERS_FILE_NAME}
    ...    overwrite=True

Read orders from csv file
    ${ORDERS_FILE_URL}=    Collect the URL of the orders CSV file from user
    Download the Orders CSV file    ${ORDERS_FILE_URL}
    ${orders}=
    ...    Read table from CSV
    ...    ${DOWNLOAD_DIR}${/}orders.csv
    ...    header=True
    RETURN    ${orders}

Fill up the order details
    [Arguments]    ${order}
    Select From List By Value    id:head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    css:input[type='number']    ${order}[Legs]
    Input Text    address    ${order}[Address]

Preview the robot order
    Click Button    preview

Place the order
    Click Button    order
    Wait Until Element Is Visible    id:receipt

Save the order HTML receipt as a PDF file
    [Arguments]    ${order_number}
    ${order_receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    ${pdf_receipt }=    Set Variable    ${PDF_RECEIPTS_DIR}${/}pdf_receipts_${order_number}.pdf
    Html To Pdf    ${order_receipt_html}    ${pdf_receipt }
    RETURN    ${pdf_receipt }

Screenshot robot preview image
    [Arguments]    ${order_number}
    Wait Until Element Is Visible    id:robot-preview-image
    ${robot_img}=    Set Variable    ${ROBOT_IMAGES_DIR}${/}robot_img_${order_number}.png
    Screenshot
    ...    id:robot-preview-image
    ...    ${robot_img}
    RETURN    ${robot_img}

Embed robot preview image to the PDF receipt
    [Arguments]    ${robot_preview_img}    ${pdf_receipt}
    Open Pdf    ${pdf_receipt}
    ${robot_image}=    Create List
    ...    ${robot_preview_img}:align=center
    Add Files To Pdf    ${robot_image}    ${pdf_receipt}
    Close Pdf

Go to order another robot
    Click Button    id:order-another

Create ZIP Archive of the receipts
    Archive Folder With Zip    ${PDF_RECEIPTS_DIR}    ${OUTPUT_DIR}/PDF_RECEPTS.ZIP

Success Dialog
    Add icon    Success
    Add heading    All orders have been placed and all receipts are archived.
    Add files    *.zip
    Run dialog    title=Success
