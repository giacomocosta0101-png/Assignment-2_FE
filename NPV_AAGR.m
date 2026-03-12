function NPV = NPV_AAGR(datesCF, startCF, reference_date, AAGR, CF0, dates, discounts)

% FIX: converti in datenum se datetime
if isdatetime(datesCF)
    datesCF = datenum(datesCF);
end
if isdatetime(startCF)
    startCF = datenum(startCF);
end

[startYear, ~, ~] = datevec(startCF);

CF = zeros(size(datesCF));

for i = 1:length(datesCF)
    t = datesCF(i);
    [y, m, ~] = datevec(t);
    years_passed = y - startYear;
    if m < 3
        years_passed = years_passed - 1;
    end
    years_passed = max(years_passed, 0);
    CF(i) = CF0 * (1 + AAGR)^years_passed;
end

NPV = 0;
for i = 1:length(datesCF)
    df = get_discount_factor_by_zero_rates_linear_interp(reference_date, datesCF(i), dates, discounts);
    NPV = NPV + CF(i) * df;
end

end