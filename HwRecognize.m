%by Gao Yang, SDCS, Sun Yat-Sen University
%18.1.27
%——————————————————————————————————————————
image = imread('input.jpg');
%imshow(image);

gi = rgb2gray(image);%rgb to gray
[m,n] = size(gi);%求图像大小
%imshow(gi);

edges = edge(gi,'Sobel', 0.06);
%imshow(edges);

%提取纸张边缘线段
[H,T,R] = hough(edges);
P = houghpeaks(H,10,'threshold',ceil(0.3 * max(H(:))));
lines = houghlines(edges,T,R,P,'FillGap',400,'MinLength',200);
%imshow(img), hold on

%计算线段延长线交点以获得四个角点
Line_horizontal = zeros(2,2);
horizontal_count = 0;
Line_vertical = zeros(2,2);
vertical_count = 0;
for i = 1:length(lines)
    k = (lines(i).point1(2) - lines(i).point2(2))/(lines(i).point1(1) - lines(i).point2(1));%求斜率k，原点在左上角
    b = lines(i).point1(2) - k * lines(i).point1(1);%求函数中的常数b
    if abs(k) > 1
        vertical_count = vertical_count + 1;
        Line_vertical(vertical_count, :) = [k, b];
    else
        horizontal_count = horizontal_count + 1;
        Line_horizontal(horizontal_count, :) = [k, b];
    end
end
x1 = (Line_horizontal(1, 2) - Line_vertical(1, 2))/(Line_vertical(1, 1) - Line_horizontal(1, 1));
y1 = Line_vertical(1, 1) * x1 + Line_vertical(1, 2);
x2 = (Line_vertical(1, 2) - Line_horizontal(2, 2))/(Line_horizontal(2, 1) - Line_vertical(1, 1));
y2 = Line_vertical(1, 1) * x2 + Line_vertical(1, 2);
x3 = (Line_horizontal(2, 2) - Line_vertical(2, 2))/(Line_vertical(2, 1) - Line_horizontal(2, 1));
y3 = Line_horizontal(2, 1) * x3 + Line_horizontal(2, 2);
x4 = (Line_vertical(2, 2) - Line_horizontal(1, 2))/(Line_horizontal(1, 1) - Line_vertical(2, 1));
y4 = Line_vertical(2, 1) * x4 + Line_vertical(2, 2);

%将四个点对应到原图四角
moving_points = [x1, y1; x2, y2; x3, y3; x4, y4];
fixed_points = [1, 1; 1, 1440; 1080, 1440; 1080, 1];
tform = fitgeotrans(moving_points, fixed_points, 'projective');
gi = imwarp(image, tform, 'OutputView', imref2d(size(image)));
%imshow(gi);

gi = rgb2gray(gi);
newi = imbinarize(gi, 0.64);%二值化0.64阈值分割
newi = ~newi;%这里取反是因为我们要提取的是深色图形
%imshow(newi);

se = strel('disk', 1);%圆形图像膨胀处理，1为倍数
A = imdilate(newi, se);
imshow(A);

[l,ma] = bwlabel(A, 8);%联通区域检测
imshow(gi);
hold on
for k = 1:ma
           [a,b] = find(l == k);
           max_a = max(a);
           max_b = max(b);
           min_a = min(a);
           min_b = min(b);
           width = max_a - min_a + 1;
           height = max_b - min_b + 1;
           %画出矩形
           rectangle('position',[min_b, min_a, height, width], 'edgecolor', 'g', 'LineWidth', 2);
           %将所有矩阵区域裁出，保留数字图即可，保存在digit文件夹中
            imwrite(gi(min_a:max_a, min_b:max_b),['figure',num2str(k),'.jpg'],'jpg');
end
