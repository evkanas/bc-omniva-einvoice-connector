# Business Central Omniva Supplier Invoice Connector

Portfolio project by **Evaldas Jablonskas**, Microsoft Dynamics 365 Business Central AL / NAV Developer.

This repository demonstrates a Microsoft Dynamics 365 Business Central AL extension for importing supplier invoices digitized by Omniva into Business Central through a SOAP API.

The project shows practical experience with Business Central integrations, XML processing, supplier invoice automation, data validation, and Job Queue-based background processing.

> This is a sanitized portfolio sample. Sensitive configuration values, credentials, customer-specific mappings, deployment settings, and proprietary business logic have been removed or replaced with neutral placeholders.

## Functional Scope

The extension demonstrates how Business Central can receive, validate, and process supplier invoices digitized by Omniva.

Main functional areas include:

* Importing digitized supplier invoices from Omniva through a SOAP API.
* Parsing supplier invoice headers, lines, VAT information, dimensions, and related document data.
* Validating vendors, vendor bank accounts, G/L accounts, items, locations, and dimensions.
* Creating purchase invoices and purchase credit memos in Business Central.
* Supporting automatic document release and posting.
* Exporting selected master data from Business Central to the external service.
* Processing supplier invoices manually or through Business Central Job Queue.
* Recording validation, integration, and processing errors.

## Business Central Capabilities Demonstrated

This portfolio project demonstrates experience with:

* Microsoft Dynamics 365 Business Central extension development.
* AL application structure and object organization.
* SOAP web service communication.
* XML document parsing and transformation.
* Supplier invoice import automation.
* Purchase invoice and purchase credit memo creation.
* Vendor, item, G/L account, location, and dimension validation.
* Job Queue automation.
* Integration error logging and diagnostics.
* Business process automation inside Business Central.

## Technical Architecture

The solution is organized around the following responsibilities:

* SOAP API communication with Omniva.
* XML response parsing and data extraction.
* Business Central master data validation.
* Purchase document creation.
* Optional release and posting automation.
* Master data export.
* Setup and configuration.
* Error logging and integration diagnostics.

## Repository Purpose

This repository is part of the Business Central development portfolio of **Evaldas Jablonskas**.

It is intended to demonstrate real-world AL development experience in supplier invoice import, Omniva integration, XML processing, validation logic, purchase document automation, and background processing in Microsoft Dynamics 365 Business Central.

The repository is not intended to be used as a production-ready connector without additional customer-specific configuration, security review, testing, and adaptation to the target Omniva service environment.