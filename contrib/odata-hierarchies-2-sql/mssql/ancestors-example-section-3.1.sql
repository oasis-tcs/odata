USE [SalesDemoDB];

-- GET ~/SalesOrganizations?$apply=
--    ancestors(SalesOrgHierarchy,
--              filter(contains(Name,'East') or contains(Name,'Central'))

WITH
	parent_of ([node], [parent_node]) AS
	(
		SELECT id, Superordinate
		FROM SalesOrganization
	),
	ancestors_of (node)	AS
	-- generic parent relation from hier def
	(
		-- set of (parent) start nodes from filter expression passed to ancestors()
		SELECT parent_node
			FROM SalesOrganization
			INNER JOIN parent_of ON parent_of.[node] = id
			WHERE CHARINDEX('East', SalesOrganization.[Name]) > 0 OR CHARINDEX('Central', SalesOrganization.[Name]) > 0
		UNION ALL
			-- generic ancestors recursion derived from hierarchy definition
			SELECT parent_node
			FROM ancestors_of INNER JOIN parent_of ON parent_of.node = ancestors_of.node		
	)
SELECT DISTINCT SalesOrganization.*
FROM SalesOrganization INNER JOIN ancestors_of ON id = node
;


-- variation: KEEP START, i.e.
-- GET ~/SalesOrganizations?$apply=
--    ancestors(SalesOrgHierarchy,
--              filter(contains(Name,'East') or contains(Name,'Central'),keep start)

WITH
	parent_of (node, parent_node) AS
	(
		SELECT id, Superordinate
		FROM SalesOrganization
	),
	-- generic parent relation from hier def
	ancestors_of (node)	AS
	(
		-- set of (parent) start nodes from filter expression passed to ancestors()
		SELECT ID
		FROM SalesOrganization
		WHERE CHARINDEX('East', SalesOrganization.[Name]) > 0 OR CHARINDEX('Central', SalesOrganization.[Name]) > 0
	UNION ALL
		-- generic ancestors recursion derived from hierarchy definition
		SELECT parent_node
		FROM ancestors_of INNER JOIN parent_of ON parent_of.node = ancestors_of.node
	)
SELECT DISTINCT SalesOrganization.*
FROM SalesOrganization INNER JOIN ancestors_of ON id = node  -- output result
;
