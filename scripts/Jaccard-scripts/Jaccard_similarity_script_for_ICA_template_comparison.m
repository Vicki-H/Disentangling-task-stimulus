%%Matlab script to compute Jaccard similarity coefficient between one or more
%%template images and ICA component results. written by Claude Bajada and
%%Becky Jackson in the Neuroscience and Aphasia Research Unit, University
%%of Manchester
clc;clear;
template_folder = '\\cbsu\data\Group\MLR-Lab\VHodgson\AH\derivatives\network_overlap\templates';
results_folder = '\\cbsu\data\Group\MLR-Lab\VHodgson\AH\derivatives\network_overlap\results';
output_folder = '\\cbsu\data\Group\MLR-Lab\VHodgson\AH\derivatives\network_overlap'; %uigetdir('','Please select folder to save output matrix');

templates = cellstr(ls(strcat(template_folder, '\*.img')));
results_data = cellstr(ls(strcat(results_folder, '\*.img')));

my_similarity_matrix_jac = zeros( length(templates) ,  length(results_data) );
% my_similarity_matrix_A = zeros( length(templates) ,  length(results_data) );
% my_similarity_matrix_B = zeros( length(templates) ,  length(results_data) );


for i = 1 : length(templates)

    %% Jaccard similarity (i.e. similarity of voxels that are involved in either component)

    template_image = extract_read_image(strcat(template_folder, '\', templates{i}));
    bin_template_image = +logical(template_image);
    
    for j = 1 : length(results_data)

        results_image = extract_read_image(strcat(results_folder,'\', results_data{j}));
        
        % convert into binary (already done with template image above)
        bin_results_image = +logical(results_image);
        
        % comp_dif - for each voxel, are they the same or different? 1 if different, 0 if not
        comp_dif = abs(bin_template_image - bin_results_image);
        % comp_dif_sum - total sum of these difference values across the space (3 nested functions for x,y,z)
        comp_dif_sum = sum(sum(sum(comp_dif)));
        
        % dif_total perhaps a misnomer? - creating the denominator, getting union of A & B
        % the +logical() here is because there might be values of 2 when summing
        comp_dif_total = sum(sum(sum(+logical(bin_template_image + bin_results_image))));
        
        % 1- because you actually want to be doing similarity/total, not dif/total
        comp_dif_pcnt = 1 - (comp_dif_sum / comp_dif_total);
             
        my_similarity_matrix_jac(i,j) = comp_dif_pcnt;
        
    end
    
end

% for i = 1 : length(templates)
% 
%     %% Proportion of template, that is also activated in results
% 
%     template_image = extract_read_image(strcat(template_folder, '\', templates{i}));
%     bin_template_image = +logical(template_image);
%     
%     for j = 1 : length(results_data)
% 
%         results_image = extract_read_image(strcat(results_folder,'\', results_data{j}));
%         
%         % convert into binary (already done with template image above)
%         bin_results_image = +logical(results_image);
%         
%         for x=1:97
%             for y=1:115
%                 for z=1:97
%                     if (bin_template_image(x,y,z)==1 && bin_results_image(x,y,z)==1)
%                         bin_match_image(x,y,z)=1;
%                     else
%                         bin_match_image(x,y,z)=0;
%                     end
%                 end
%             end
%         end
%         
%         comp_prop = sum(sum(sum(bin_match_image)));
% 
%         comp_dif_pcnt_A = sum(sum(sum(bin_match_image)))/sum(sum(sum(bin_template_image)));
% 
%         my_similarity_matrix_A(i,j) = comp_dif_pcnt_A;
%         
%     end
%     
% end
% 
% for i = 1 : length(templates)
% 
%     %% Proportion of results, that is also activated in template
%     
%     % differs only from the above section in the final division (denom)
% 
%     template_image = extract_read_image(strcat(template_folder, '\', templates{i}));
%     bin_template_image = +logical(template_image);
%     
%     for j = 1 : length(results_data)
% 
%         results_image = extract_read_image(strcat(results_folder,'\', results_data{j}));
%         
%         % convert into binary (already done with template image above)
%         bin_results_image = +logical(results_image);
%         
%         for x=1:97
%             for y=1:115
%                 for z=1:97
%                     if (bin_template_image(x,y,z)==1 && bin_results_image(x,y,z)==1)
%                         bin_match_image(x,y,z)=1;
%                     else
%                         bin_match_image(x,y,z)=0;
%                     end
%                 end
%             end
%         end
%         
%         comp_dif_pcnt_B = sum(sum(sum(bin_match_image)))/sum(sum(sum(bin_results_image)));
% 
%         my_similarity_matrix_B(i,j) = comp_dif_pcnt_B;
%         
%     end
%     
% end

%add labels to results matrix
my_similarity_matrix_jac_labelled = horzcat(templates, num2cell(my_similarity_matrix_jac));
% my_similarity_matrix_A_labelled = horzcat(templates, num2cell(my_similarity_matrix_A));
% my_similarity_matrix_B_labelled = horzcat(templates, num2cell(my_similarity_matrix_B));

e = zeros(length(results_data)+1, 1);
e=num2cell(e);
for i =2:(length(results_data)+1);
e(i, 1) = results_data(i-1, 1);
end

e=e';
my_similarity_matrix_jac_labelled=vertcat(e,my_similarity_matrix_jac_labelled)';
% my_similarity_matrix_A_labelled=vertcat(e,my_similarity_matrix_A_labelled)';
% my_similarity_matrix_B_labelled=vertcat(e,my_similarity_matrix_B_labelled)';

%save results matrix
cd(output_folder)
save my_similarity_matrix_jac_labelled_RS.mat, my_similarity_matrix_jac_labelled
%clearvars -except my_similarity_matrix_comp_labelled

