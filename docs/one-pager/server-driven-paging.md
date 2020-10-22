# Server-Driven Paging

## Basic Choreography

When a client reads a list of things, and the result is too long to return in one chunk, server-driven paging can kick in.

This essentially means that the server returns the first part of the response, plus a next-link. For a JSON response this means there is a member `@odata.nextLink` in the outermost object of the response, whose string value is a URL that the client can use to `GET` the next part of the response.

The next part may again contain an `@odata.nextLink`, until the client receives the final page, which does not contain an `@odata.nextLink`.

Or the client can give up because it had enough already before reaching the end of the result.

Server-driven paging also helps protecting against denial-of-service attacks by limiting results to a reasonable page size: large enough to not get clogged down with next-link requests, and small enough to not overly stress server resources when producing the next page.

Btw., we didn't invent this, this was copied from the [Atom Publishing Protocol](https://tools.ietf.org/html/rfc5023#section-10.1), which was all the rage back in 2009.


## Advanced Choreography, combined with Delta

Delta is a mechanism to only receive changes (inserts, updates, and deletes) to a large list of things that has already been read some time ago.

As the initial list is typically large, it is read in combination with server-driven paging.

### Initial Load

The initial load is triggered by the client, requesting all relevant content:

* `GET /stuff?$filter=color eq 'red'`

If that content is large, the server uses server-driven paging and only sends the first page of the requested data with an `@odata.nextLink`.

As described above the client follows next-links until it reaches the last page.

The last page now contains a delta-link (in JSON a member `@odata.deltaLink`) and of course no next-link, indicating to the client that the server supports delta load.

The client stores that delta-link for a later refresh.

![Initial Load](initial-load.png)


### Delta Load

When the client wants to refresh the initial content some time later, it sends a `GET` request to the delta-link that it received and stored earlier.

The server responds with all relevant content that has been added, changed, or deleted since the server issued that delta-link.

If the delta is large, the server uses server-driven paging and only sends the first page of the delta, with a next-link.

Again the client follows next-links until it reaches the last page with a delta-link, which the client again stores for the next refresh cycle.

![Delta Load](delta-load.png)

