num_text = 5;
sample_text = ['A';'B';'C';'D';'E'];
for i = 1:num_text
    disp(sample_text(i))
    if i == 3
        return;
    end
end