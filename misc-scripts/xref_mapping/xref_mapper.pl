#!/usr/bin/perl


use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;
use Cwd;
use XrefMapper::db;
use XrefMapper::SubmitMapper;
use XrefMapper::ProcessMappings;
use XrefMapper::ProcessPrioritys;
use XrefMapper::ProcessPaired;
use XrefMapper::CoreInfo;
use XrefMapper::TestMappings;
use XrefMapper::XrefLoader;
use XrefMapper::Interpro;
use XrefMapper::DisplayXrefs;


use vars qw(@INC);

$| = 1;

my $file;
my $dumpcheck;
my $upload;
my $nofarm;

print "Options: ".join(" ",@ARGV)."\n";

GetOptions ('file=s'                    => \$file,
            'dumpcheck'                 => \$dumpcheck, 
            'upload'                    => \$upload,
            'nofarm'                    => \$nofarm );



my $mapper = XrefMapper::SubmitMapper->process_file($file);

########################TEST########################
#my $core_info = XrefMapper::CoreInfo->new($mapper);
#$core_info->test_return_codes();
#exit;
####################################################



if(defined($dumpcheck)){
  $mapper->dumpcheck("yes");
}
if(defined($nofarm)){
  $mapper->nofarm("yes");
}
 

# find out what stage the database is in at present.
my $status = $mapper->xref_latest_status(1);
print "current status is $status\n";



if( $status eq "parsing_finished"){ 
  print "\nDumping xref & Ensembl sequences\n";
  $mapper->dump_seqs();
  $status =  $mapper->xref_latest_status();
}
else{
  $mapper->no_dump_xref()
}



$status = $mapper->xref_latest_status();
if($status eq "core_fasta_dumped"){
  $mapper->build_list_and_map();
  $status =  $mapper->xref_latest_status();
}
else{

}

$status = $mapper->xref_latest_status();
if($status eq "mapping_started"){
  die "Status is $status so a job is already doing the mapping. Please wait till it has finished";
}
elsif($status eq "mapping_finished"){
  my $parser = XrefMapper::ProcessMappings->new($mapper);
  $parser->process_mappings();
}

$status = $mapper->xref_latest_status();
if($status eq "mapping_processed"){  # load core data needed and add direct xrefs to the object_xref etc tables
  my $core_info = XrefMapper::CoreInfo->new($mapper);
  $core_info->get_core_data();
}


$status = $mapper->xref_latest_status();
if($status eq "direct_xrefs_parsed"){  # process the priority xrefs.
  my $pp = XrefMapper::ProcessPrioritys->new($mapper);
  $pp->process();
}


# pair data
$status = $mapper->xref_latest_status();
if($status eq "prioritys_flagged"){  # process the inferred pairs and interpro xrefs.
  my $pp = XrefMapper::ProcessPaired->new($mapper);
  $pp->process();

  my $inter = XrefMapper::Interpro->new($mapper);
  $inter->process();
}
#$mapper->biomart_test();


# Biomart test each external_db on one ensembl type only and fix it
$status = $mapper->xref_latest_status();
if($status eq "processed_pairs"){ 
  $mapper->biomart_testing();
}

# species specific processing
# i.e. for mouse and human add MGI_curated_gene and HGNC_curated_gene

#$mapper->biomart_test();

$status = $mapper->xref_latest_status();
if($status eq "processed_pairs"){ 
  $mapper->official_naming();
}
#$mapper->biomart_test();


# Coordinate xrefs

# tests
$status = $mapper->xref_latest_status();
if($status eq "official_naming_done" || $status eq "tests_started" || $status eq "tests_failed" ){  # process the priority xrefs.
  my $tester = XrefMapper::TestMappings->new($mapper);
  if($tester->unlinked_entries){
    die "Problems found so will not load core database\n";
  }
  $tester->direct_stable_id_check(); # Will only give warnings
  $tester->entry_number_check();     # Will only give warnings
  $tester->name_change_check();      # Will only give warnings
}

# load into core database
$status = $mapper->xref_latest_status();
if($status eq "tests_finished"){


  $mapper->run_coordinatemapping($upload);
 

  my $loader = XrefMapper::XrefLoader->new($mapper);
  $loader->update();

}

# generate display_xrefs and descriptions for gene and transcripts. 

$status = $mapper->xref_latest_status();
if($status eq "core_loaded" or $status eq "display_xref_done"){

  my $display = XrefMapper::DisplayXrefs->new($mapper);
  $display->genes_and_transcripts_attributes_set();

}





























