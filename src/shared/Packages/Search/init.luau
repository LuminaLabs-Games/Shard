local function BinarySearch(array: { any }, value: any)
	local left = 1
	local right = #array

	while left <= right do
		local middle = left + (right - left) // 2

		if array[middle] == value then
			return middle
		elseif array[middle] < value then
			left = middle + 1
		else
			right = middle - 1
		end
	end

	return nil
end

return {
	BinarySearch = BinarySearch,
}
