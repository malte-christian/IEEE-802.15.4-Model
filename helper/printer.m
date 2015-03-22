h1=figure;
plot(0:1:119, delay_t)
hold on
plot(0:10:120, delay_test_results)
plot(10:10:100, practical_results)


legend('Analytical Model without interference', 'Analytical Model with interference (3 nodes, full buffer)', 'Practical experiment (noise unkown)')
xlabel('payload [byte]')
ylabel('mean delay of 200 packets [s]')

% print with 300 ppi
print(h1,'-dpng','-r300','test.png')