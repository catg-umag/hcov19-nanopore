nextflow.enable.dsl = 2


workflow LineageAssesment {
  take:
    consensus       // single FASTA file containing all consensuses

  main:
    consensus
      | (assignPangolin & assignNextstrain)

    mergeLineages(
      assignPangolin.out,
      assignNextstrain.out
    )

  emit:
    lineages = mergeLineages.out
}


process assignPangolin {
  label 'pangolin'
  publishDir "${params.output_directory}/lineages", mode: 'copy'

  input:
  path(consensus)

  output:
  path('pangolin_lineages.csv')
  
  script:
  """
  pangolin $consensus --outfile pangolin_lineages.csv
  """
}


process assignNextstrain {
  label 'nextclade'
  publishDir "${params.output_directory}/lineages", mode: 'copy'

  input:
  path(consensus)

  output:
  path('nextstrain_lineages.csv')

  script:
  """
  nextclade dataset get --name 'sars-cov-2' --output-dir 'data_sars-cov-2'

  nextclade \
    --input-fasta=$consensus \
    --input-dataset data_sars-cov-2 \
    --output-csv=nextstrain_lineages.csv \
    --output-dir=.
  """
}


process mergeLineages {
  label 'python'

  input:
  path(pangolin_lineages)
  path(nextstrain_lineages)

  output:
  path('all_lineages.csv')

  script:
  """
  merge_lineage_info.py \
    --pangolin $pangolin_lineages \
    --nextstrain $nextstrain_lineages \
    --output all_lineages.csv
  """
}