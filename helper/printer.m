h1=figure;
plot(1:1:120, delay_t)
hold on
plot(10:10:100, delay_inter)
plot(10:10:100, delay_test)


legend('Analytical Model without interference', 'Analytical Model with interference', 'Practical experiment')
xlabel('payload [byte]')
ylabel('mean delay of 200 packets [s]')

% print with 300 ppi
print(h1,'-dpng','-r300','test.png')