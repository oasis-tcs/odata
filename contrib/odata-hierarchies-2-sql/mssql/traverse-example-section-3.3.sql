USE [SalesDemoDB];

-- logic for a depth first search traversal of a hierarchy
WITH 
  -- traversal needs a stable sibling order; can be rowid if selecting from hierarchy table, or row_number() if preceding transformation
	salesorg_w_sibling(ID,Superordinate,Name,SiblingIdx) AS
	(
		SELECT *,  CAST(ROW_NUMBER() OVER(ORDER BY (SELECT 1)) AS varchar(8000)) 
		FROM SalesOrganization
	),
	parent_of(node,parent_node) AS
	(
		SELECT id, Superordinate
		FROM salesorg_w_sibling
	),
	dfs_traversal_of(node, path) AS
	(
		SELECT id, SiblingIdx
		FROM salesorg_w_sibling
		-- start with root node
		WHERE Superordinate IS NULL
	UNION ALL
		SELECT parent_of.node, path + '.' + SiblingIdx 
		-- build lexicographical sequence for each node
		FROM dfs_traversal_of
		INNER JOIN parent_of ON parent_of.parent_node = dfs_traversal_of.node
		INNER JOIN salesorg_w_sibling ON parent_of.node = salesorg_w_sibling.id
    )
SELECT SalesOrganization.*, dfs_traversal_of.path
FROM SalesOrganization INNER JOIN dfs_traversal_of ON id = node
ORDER BY dfs_traversal_of.path ASC
;


-- applied to example from spec:
-- GET ~/SalesOrganizations?$apply=
--     descendants(SalesOrgHierarchy,filter(Name eq 'US'),keep start)
--     /ancestors(SalesOrgHierarchy,filter(contains(Name,'East')),keep start)
--     /traverse(SalesOrgHierarchy,preorder)

-- Develop the different transformations in two steps

-- step #1: $apply=descendants(...)/ancestors(...)

WITH 
	parent_of(node,parent_node) AS
	(
		SELECT id, Superordinate
		FROM SalesOrganization
	), -- generic parent relation from hier def
	descendants_of (node) AS
	(
		SELECT id
		FROM SalesOrganization
		-- set of start nodes from filter expression passed to descendants()
		WHERE name = 'US'
	UNION ALL
		SELECT parent_of.node
		-- generic descendants recursion derived from hier def
		FROM descendants_of INNER JOIN parent_of ON parent_of.parent_node = descendants_of.node
    ),
	trafo_1_result(ID,SuperOrdinate,Name) AS
	( -- result of descendants(...)
		SELECT SalesOrganization.*
		FROM SalesOrganization INNER JOIN descendants_of ON id = node
    ),	
	ancestors_of (node) AS -- CTEs for ancestors
	(
		SELECT ID
		FROM trafo_1_result
		-- set of start nodes from filter expression and considering "keep start"
		WHERE charindex('East', name) <> 0
	UNION ALL
		SELECT parent_node
		FROM ancestors_of INNER JOIN parent_of ON parent_of.node = ancestors_of.node
    )
SELECT trafo_1_result.*
FROM trafo_1_result INNER JOIN ancestors_of ON id = node
;


-- step #2: $apply=descendants(...)/ancestors(...)//traverse(SalesOrgHierarchy,preorder)
WITH 
	-- CTEs for descendants
	parent_of (node,parent_node) AS
	(
		SELECT id, Superordinate
		FROM SalesOrganization
	), 
	descendants_of (node) AS -- generic parent relation from hier def
	(
		-- set of start nodes from filter expression passed to descendants()
		SELECT id
		FROM SalesOrganization		
		WHERE name = 'US'
	UNION ALL
		-- generic descendants recursion derived from hier def 
		SELECT parent_of.node		
		FROM descendants_of INNER JOIN parent_of ON parent_of.parent_node = descendants_of.node
    ) ,
	trafo_1_result (ID,SuperOrdinate,Name,SiblingIndex) AS
	(
		-- result of descendants(...), use row_id as sibling order
		SELECT SalesOrganization.*, CAST(ROW_NUMBER() OVER(ORDER BY (SELECT 1)) AS varchar(8000))  -- SalesOrganization.rowid
		FROM SalesOrganization, descendants_of
		WHERE id = node
    ) ,
	-- CTEs for ancestors
	ancestors_of (node) AS
	(
		SELECT ID
		FROM trafo_1_result
		-- set of start nodes from filter expression and considering "keep start"
		WHERE charindex('East', name) <> 0
	UNION ALL
		SELECT parent_node
		FROM ancestors_of INNER JOIN parent_of ON parent_of.node = ancestors_of.node
    ) ,
	trafo_2_result (ID,SuperOrdinate,Name,SiblingIndex) AS
	( 
		-- result of ancestors(...)
		SELECT trafo_1_result.*
		FROM trafo_1_result INNER JOIN ancestors_of ON id = node
    ) ,
	-- CTEs for traverse
	parent_of2 (node,parent_node) AS
	(
		SELECT id, Superordinate
		FROM trafo_2_result
	),
	dfs_traversal_of (node, path) AS
	(
		SELECT id, SiblingIndex
		FROM trafo_2_result
		WHERE name = 'US'
	UNION ALL
		SELECT parent_of2.node,  CAST(path + '.' + cast(SiblingIndex AS varchar) AS varchar(8000))
		FROM dfs_traversal_of
		INNER JOIN parent_of2 ON parent_of2.parent_node = dfs_traversal_of.node
		INNER JOIN trafo_2_result ON parent_of2.node = trafo_2_result.id
    )
-- select * from salesorg_w_sibling_id
SELECT trafo_2_result.ID, trafo_2_result.SuperOrdinate, trafo_2_result.Name, dfs_traversal_of.path
FROM trafo_2_result INNER JOIN dfs_traversal_of ON id = node
ORDER BY dfs_traversal_of.path ASC    
;

