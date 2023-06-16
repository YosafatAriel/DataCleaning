/*
THIS IS BASED ON EXCEL FILES FROM https://github.com/AlexTheAnalyst/PortfolioProjects/blob/main/Nashville%20Housing%20Data%20for%20Data%20Cleaning%20(reuploaded).xlsx
Cleaning Data in SQL Queries
*/

-->> Standardize Date Format <<--
ALTER TABLE NashvilleHousing
Add SaleDateConverted Date;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(date, SaleDate)

SELECT SaleDateConverted, CONVERT(date, SaleDate)
FROM NashvilleHousing

---------------------------------------------------------------------------------------------------------------------

-->> Populate Property Address Data <<--

-- CHECK if there are nulls value in 'PropertyAddress' Column
-- We need to SELF JOIN TABLE with alias to check nulls value and test to populate it
-- using ISNULL('columnarea to check', 'columnarea as a result') and there are 35 NULLS value.
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing AS a
JOIN NashvilleHousing AS b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

-- after we check and test to populate it
-- we can update it
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing AS a
JOIN NashvilleHousing AS b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

-- check
Select *
From PortfolioProject.dbo.NashvilleHousing
Where PropertyAddress is null
order by ParcelID

---------------------------------------------------------------------------------------------------------------------

-->> Breaking out Address into Individual Columns (Address, City, State) <<--

-- use SUBSTRING to extract from column PropertyAddress that have delimiter value
-- SUBSTRING(string, start, length) <== Syntax
-- CHARINDEX(substring, string, start) <== Syntax
-- Test
SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Address1,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS Address2
FROM NashvilleHousing

-- and make new different column for split address  with ALTER and UPDATE 
ALTER TABLE NashvilleHousing
Add PropertySplitAddress Nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) 

-- and make new different column for split city with ALTER and UPDATE 
ALTER TABLE NashvilleHousing
Add PropertySplitCity Nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))

SELECT *
FROM NashvilleHousing

---------------------------------------------------------------------------------------------------------------------

-->> Breaking out OwnerAddress into Individual Columns (Address, City, State) <<--

-- Easy with PARSENAME()
-- PARSENAME ( 'object_name' , object_part ) <= syntax
-- inside PARSENAME() using REPLACE(string, old_string, new_string) 
-- Test
SELECT
PARSENAME(REPLACE(OwnerAddress, ',','.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',','.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',','.'), 1)
FROM NashvilleHousing

-- Make new column OwnerSplitAddress
ALTER TABLE NashvilleHousing
Add OwnerSplitAddress Nvarchar(255);

-- UPDATE it with value using PARSENAME function to split and replace
UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',','.'), 3)
 
-- Make new column OwnerSplitCity
ALTER TABLE NashvilleHousing
Add OwnerSplitCity Nvarchar(255);

-- UPDATE it with value using PARSENAME function to split and replace
UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',','.'), 2)

-- Make new column OwnerSplitState
ALTER TABLE NashvilleHousing
Add OwnerSplitState Nvarchar(255);

-- UPDATE it with value using PARSENAME function to split and replace
UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',','.'), 1)

SELECT *
FROM NashvilleHousing
---------------------------------------------------------------------------------------------------------------------

-->> Change Y and N to Yes and No in "Sold as Vacant" field <<--
-- Test
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2


SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
	 END
FROM NashvilleHousing

UPDATE NashvilleHousing
SET SoldAsVacant = 
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
END

-----------------------------------------------------------------------------------------------------------------------

-->> Remove Duplicates <<--
WITH RowNumCTE AS (
	SELECT *,
		ROW_NUMBER() OVER (
			PARTITION BY ParcelId,
						 PropertyAddress,
						 SalePrice,
						 SaleDate,
						 LegalReference
						 ORDER BY
							uniqueID
						 ) row_num
FROM NashvilleHousing	
)

SELECT *
FROM RowNumCTE
WHERE row_num > 1

--DELETE
--FROM RowNumCTE
--WHERE row_num > 1


-->> Delete Unused Columns <<--
ALTER TABLE NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

SELECT *
FROM NashvilleHousing