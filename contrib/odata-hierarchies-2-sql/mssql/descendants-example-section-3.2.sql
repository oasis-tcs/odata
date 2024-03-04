USE [SalesDemoDB];


-- GET ~/SalesOrganizations?$apply=
--    descendants(SalesOrgHierarchy,filter(Name eq 'US'),keep start)

WITH
	parent_of([node], [parent]) AS
	(
		SELECT [id], [Superordinate]
		FROM [SalesOrganization]
	),  
	descendants_of(node) AS -- generic parent relation from hier def
	(
		-- set of start nodes from filter expression passed to descendants()
		SELECT [id]
		FROM [SalesOrganization]		
		WHERE [name] = 'US'
    UNION ALL
		-- generic descendants recursion derived from hier def
		SELECT parent_of.[node]		
		FROM descendants_of INNER JOIN parent_of ON parent_of.[parent] = descendants_of.node
	)
SELECT [SalesOrganization].*
FROM [SalesOrganization] INNER JOIN descendants_of ON [id] = [node]  -- output result
;

-- variation: no KEEP START, i.e.
-- GET ~/SalesOrganizations?$apply=
--    descendants(SalesOrgHierarchy, filter(Name eq 'US'))

WITH
	parent_of(node, parent_node) AS -- generic parent relation from hier def
	( 
		SELECT id, [Superordinate]
		FROM [SalesOrganization]
	), 
	descendants_of	(node) AS
	(
		SELECT node -- set of (children) start nodes from filter expression passed to descendants()			
		FROM [SalesOrganization] INNER JOIN parent_of ON parent_of.parent_node = id
		WHERE name = 'US'
	UNION ALL
		SELECT parent_of.node	-- generic descendants recursion derived from hier def
		FROM descendants_of INNER JOIN parent_of ON parent_of.parent_node = descendants_of.node
    )
SELECT [SalesOrganization].*
FROM [SalesOrganization], descendants_of
WHERE id = node  -- output result
;
