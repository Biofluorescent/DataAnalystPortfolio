/*
	Cleaning Data: SQL Queries
	Nashville Housing Data
*/

SELECT *
FROM NashvilleHousing..Housing


---------------------------------------------------------------------------------------


/* Standardize Date Format */


SELECT convert(date, SaleDate)
FROM NashvilleHousing..Housing


	-- Not working for some reason
UPDATE NashvilleHousing..Housing
SET SaleDate = CONVERT(date, SaleDate)


	-- So let's add a new columnn
ALTER TABLE NashvilleHousing..Housing
ADD SaleDateConverted Date

UPDATE NashvilleHousing..Housing
SET SaleDateConverted = CONVERT(date, SaleDate)

SELECT SaleDate, SaleDateConverted FROM NashvilleHousing..Housing


------------------------------------------------------------------------------------------------


/* Populate Property Address data */


SELECT *
FROM NashvilleHousing..Housing
WHERE PropertyAddress IS NULL


	-- Test query to self join and find addresses for those that are null and their replacement
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing..Housing a
JOIN NashvilleHousing..Housing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID]  -- <> is same as !=
WHERE a.PropertyAddress IS NULL


	-- Update null addresses with values
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing..Housing a
JOIN NashvilleHousing..Housing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress IS NULL


------------------------------------------------------------------------------------------------


/* Breaking out Address into Individual Columns (Address, City, State) */

SELECT PropertyAddress
FROM NashvilleHousing..Housing


	-- Verify that each Property Address only contains 1 comma
WITH temp (Commas) AS
(
	SELECT len(PropertyAddress) - len(replace(PropertyAddress,',',''))
	FROM NashvilleHousing..Housing
)
SELECT DISTINCT(Commas) FROM temp


	-- Verify that we can split the string as desired
SELECT SUBSTRING(PropertyAddress,1, CHARINDEX(',', PropertyAddress) - 1) AS Address,
	SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS Address2
FROM NashvilleHousing..Housing


	-- Add and Update the new columns with the split strings
ALTER TABLE NashvilleHousing..Housing
ADD PropertySplitAddress nvarchar(255)

ALTER TABLE NashvilleHousing..Housing
ADD PropertySplitCity nvarchar(255)

UPDATE NashvilleHousing..Housing
SET PropertySplitAddress = SUBSTRING(PropertyAddress,1, CHARINDEX(',', PropertyAddress) - 1)

UPDATE NashvilleHousing..Housing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))


	-- Owners Values to split into columns
SELECT PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM NashvilleHousing..Housing


ALTER TABLE NashvilleHousing..Housing
ADD OwnerSplitAddress nvarchar(255)

ALTER TABLE NashvilleHousing..Housing
ADD OwnerSplitCity nvarchar(255)

ALTER TABLE NashvilleHousing..Housing
ADD OwnerSplitState nvarchar(255)


UPDATE NashvilleHousing..Housing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

UPDATE NashvilleHousing..Housing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

UPDATE NashvilleHousing..Housing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)


-------------------------------------------------------------------------------------------------


-- Change Y and N to 'Yes' and 'No' in "Sold as Vacant" field


SELECT SoldAsVacant, 
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		 WHEN SoldAsVacant = 'N' THEN 'No'
		 ELSE SoldAsVacant
	END
FROM NashvilleHousing..Housing


UPDATE NashvilleHousing..Housing
SET SoldAsVacant = 	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
						 WHEN SoldAsVacant = 'N' THEN 'No'
						 ELSE SoldAsVacant
					END

	-- Verify update
SELECT DISTINCT(SoldAsVacant) FROM NashvilleHousing..Housing

-------------------------------------------------------------------------------------------------


-- Remove Duplicates

WITH RowNumCTE AS (
SELECT *,
	ROW_NUMBER() OVER ( PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference ORDER BY UniqueID) row_num
FROM NashvilleHousing..Housing
)
DELETE 
FROM RowNumCTE
WHERE row_num > 1


-------------------------------------------------------------------------------------------------


-- Delete Unused Columns (Not to be done with raw data, here for practice)

SELECT *
FROM  NashvilleHousing..Housing

ALTER TABLE NashvilleHousing..Housing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate


------------------------------------------------------------------------------------------------

