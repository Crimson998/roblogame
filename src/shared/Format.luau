local Format = {}

-- 1234567 -> "$1,234,567"
function Format.money(amount: number): string
	local digits = tostring(math.floor(amount))
	local withCommas = digits:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if withCommas:sub(1, 1) == "," then
		withCommas = withCommas:sub(2)
	end
	return "$" .. withCommas
end

return Format
