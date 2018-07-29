Import-Module PSWInDocumentation -Force
Import-Module PSWriteWord #-Force
Import-Module ActiveDirectory

$FilePathTemplate = "$PSScriptRoot\Templates\WordTemplate.docx"

$FilePath = "$Env:USERPROFILE\Desktop\PSWriteWord-Example-Report.docx"

function Start-WinDocumentationServer {
    param (
        [string[]] $ComputerName = $Env:COMPUTERNAME,
        [string] $FilePathTemplate,
        [string] $FilePath,
        [switch] $OpenDocument,
        $CompanyName = 'Evotec'
    )
    if ($FilePathTemplate -ne $null) {
        $WordDocument = Get-WordDocument -FilePath $FilePathTemplate
    } else {
        $WordDocument = New-WordDocument -FilePath $FilePath
    }

    $ForestInformation = Get-WinADForestInformation

    $Toc = Add-WordToc -WordDocument $WordDocument -Title 'Table of content' -Switches C, A -RightTabPos 15

    $WordDocument | Add-WordSection -PageBreak

    ### 1st section - Introduction
    $Text = "This document provides a low-level design of roles and permissions for the IT infrastructure team at $CompanyName organization. This document utilizes knowledge from AD General Concept document that should be delivered with this document. Having all the information described in attached document one can start designing Active Directory with those principles in mind. It's important to know while best practices that were described are important in decision making they should not be treated as final and only solution. Most important aspect is to make sure company has full usability of Active Directory and is happy with how it works. Making things harder just for the sake of implementation of best practices isn't always the best way to go."
    $WordDocument | New-WordBlock `
        -TocEnable $True `
        -TocText 'Scope' `
        -TocListLevel 0 `
        -TocListItemType Numbered `
        -TocHeadingType Heading1 `
        -Text $Text

    $WordDocument | Add-WordSection -PageBreak

    ### Section - Forest Summary
    $WordDocument | New-WordBlockTable `
        -TocEnable $True `
        -TocText 'General Information - Forest Summary' `
        -TocListLevel 0 `
        -TocListItemType Numbered `
        -TocHeadingType Heading1 `
        -TableData $ForestInformation.ForestInformation `
        -TableDesign ColorfulGridAccent5 `
        -TableTitleMerge $True `
        -TableTitleText "Forest Summary" `
        -Text  "Active Directory at $CompanyName has a forest name $($ForestInformation.ForestName). Following table contains forest summary with important information:" -verbose

    $WordDocument | New-WordBlockTable `
        -TableData $ForestInformation.FSMO `
        -TableDesign ColorfulGridAccent5 `
        -TableTitleMerge $true `
        -TableTitleText 'FSMO Roles' `
        -Text 'Following table contains FSMO servers' `
        -EmptyParagraphsBefore 1

    $WordDocument | New-WordBlockTable `
        -TableData $ForestInformation.OptionalFeatures `
        -TableDesign ColorfulGridAccent5 `
        -TableTitleMerge $true `
        -TableTitleText 'Optional Features' `
        -Text "Following table contains optional forest features" `
        -EmptyParagraphsBefore 1

    ### Section - UPN Summary
    $WordDocument | New-WordBlockList `
        -Text "Following UPN suffixes were created in this forest:" `
        -TextListEmpty "No UPN suffixes were created in this forest." `
        -ListType Bulleted `
        -ListData $ForestInformation.UPNSuffixes `
        -EmptyParagraphsBefore 1

    $WordDocument | New-WordBlockList `
        -Text "Following SPN suffixes were created in this forest:" `
        -TextListEmpty "No SPN suffixes were created in this forest." `
        -ListType Bulleted `
        -ListData $ForestInformation.SPNSuffixes `
        -EmptyParagraphsBefore 1

    foreach ($Domain in $ForestInformation.Domains) {
        $WordDocument | Add-WordSection -PageBreak
        $DomainInformation = Get-WinDomainInformation -Domain $Domain

        $SectionDomainSummary = $WordDocument | Add-WordTocItem -Text "General Information - Domain $Domain" -ListLevel 0 -ListItemType Numbered -HeadingType Heading1
        ### Section - Domain Summary
        $SectionDomainSummary = $WordDocument | Add-WordTocItem -Text "General Information - Domain Summary" -ListLevel 1 -ListItemType Numbered -HeadingType Heading2
        $SectionDomainSummary = $WordDocument | Get-DomainSummary -Paragraph $SectionDomainSummary -ActiveDirectorySnapshot $ActiveDirectorySnapshot -Domain $Domain



        $WordDocument | New-WordBlockTable `
            -TableData $DomainInformation.FSMO `
            -TableDesign ColorfulGridAccent5 `
            -TableTitleMerge $true `
            -TableTitleText "FSMO Roles for $Domain" `
            -Text "Following table contains FSMO servers with roles for domain $Domain" `
            -EmptyParagraphsBefore 1

        $WordDocument | New-WordBlockTable `
            -TocEnable $True `
            -TocText 'General Information - Password Policies' `
            -TocListLevel 1 `
            -TocListItemType Numbered `
            -TocHeadingType Heading2 `
            -TableData $DomainInformation.DefaultPassWordPoLicy `
            -TableDesign ColorfulGridAccent5 `
            -TableTitleMerge $True `
            -TableTitleText "Default Password Policy for $Domain" `
            -Text 'Following table contains password policies'

        $WordDocument | New-WordBlockTable `
            -TocEnable $True `
            -TocText 'General Information - Group Policies' `
            -TocListLevel 1 `
            -TocListItemType Numbered `
            -TocHeadingType Heading2 `
            -TableData $DomainInformation.GroupPolicies `
            -TableDesign ColorfulGridAccent5 `
            -Text "Following table contains group policies for $Domain"

        $WordDocument | New-WordBlockTable `
            -TocEnable $True `
            -TocText 'General Information - Organizational Units' `
            -TocListLevel 1 `
            -TocListItemType Numbered `
            -TocHeadingType Heading2 `
            -TableData $DomainInformation.OrganizationalUnits `
            -TableDesign ColorfulGridAccent5 `
            -Text "Following table contains all OU's created in $Domain"

        $WordDocument | New-WordBlockTable `
            -TocEnable $True `
            -TocText 'General Information - Priviliged Members' `
            -TocListLevel 1 `
            -TocListItemType Numbered `
            -TocHeadingType Heading2 `
            -TableData $DomainInformation.PriviligedGroupMembers `
            -TableDesign ColorfulGridAccent5 `
            -Text 'Following table contains list of priviliged groups and count of the members in it.'

        $WordDocument | New-WordBlockTable `
            -TocEnable $True `
            -TocText 'General Information - Domain Administrators' `
            -TocListLevel 1 `
            -TocListItemType Numbered `
            -TocHeadingType Heading2 `
            -TableData $DomainInformation.DomainAdministrators `
            -TableDesign ColorfulGridAccent5 `
            -Text 'Following users have highest domain priviliges and are able to control a lot of Windows resources.'
    }

    Save-WordDocument -WordDocument $WordDocument -Language 'en-US' -FilePath $FilePath -Supress $true #-Verbose
    if ($OpenDocument) { Invoke-Item $FilePath }
}

Clear-Host
Start-WinDocumentationServer -ComputerName 'AD1' -FilePathTemplate $FilePathTemplate -FilePath $FilePath -OpenDocument