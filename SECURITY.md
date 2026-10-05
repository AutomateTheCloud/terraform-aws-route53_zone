# Security

## Reporting a vulnerability

Report security problems privately, not in a public issue. On GitHub, open the repository's **Security** tab and choose **Report a vulnerability**. Only the maintainers can see the report.

Include what you found, how to reproduce it, and what an attacker could do with it.

## What counts

A security problem in this module is anything that makes a hosted zone or its records more exposed or less protected than its inputs say they should be: for example, a private zone created as public, a zone associated with a VPC the caller did not list, records deleted without `force_destroy`, or a validation that lets an unsafe value through.

## Supported versions

Fixes are made to the latest release.
