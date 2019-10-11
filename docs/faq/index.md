# Frequently Asked Questions

## What is OData?

OData is a collection of REST API patterns that we collected over time and wrote down in a formalized way, making sure the patterns work consistently together.

It's also an [OASIS Standard](http://docs.oasis-open.org/odata/odata/v4.0/odata-v4.0-part1-protocol.html) and an ISO Standard: [ISO/IEC 20802-1:2016
Information technology - Open data protocol (OData) v4.0 - Part 1: Core](https://www.iso.org/standard/69208.html) and [ISO/IEC 20802-2:2016
Information technology - Open data protocol (OData) v4.0 - Part 2: OData JSON Format](https://www.iso.org/standard/69209.html), just to give it some "corporate legitimacy" :smiley:.

## Why is OData so large?

OData started back in 2009 as a Microsoft Open Specification, back then rather simple. As we discovered additional use cases, we added more patterns to the standard, with a major rework in 2012-2013, resulting in the above mentioned OASIS standard.

## Do I have to implement all of OData?

No, definitely not. 

Start with the patterns  you need, and add other patterns later when you need them. The benefit of copying the OData patterns instead of making up similar patterns on your own is that all OData patterns work nicely together.

## What is the minimum set of OData features I have to implement?

Only those that you need :smiley:.

Most use cases start with a simple list of identically structured things (think: table).

When this list is too large to be always read in one go, add filtering (`$filter`), sorting (`$orderby`), and paging (`$top` and `$skip` for client-driven paging, or [server-driven paging](../one-pager/server-driven-paging.md)).

When this list has many fields and different clients need different sets of fields, add projection (`$select`).

When the things in the list are related to other things in other lists (think: people going on trips, or developers working on projects), add navigation properties.

The above patterns are the most widely used, and you can [interactively try them out with a reference service](https://www.odata.org/odata-services/).

When the list grows over time and clients are only interested in new, changed, or deleted things, add delta.

And so on. You probably won't implement all of the OData features. I haven't :smiley:.
