function time = getTimestamp(headstamp ,sim)

if sim
    time = headstamp./ 1e9;
else
    time = headstamp.value1 ./ 1e9;
end

end