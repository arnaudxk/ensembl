
#
# BioPerl module for Protein_Adaptor
#
# Cared for by Emmanuel Mongin <mongin@ebi.ac.uk>
#
# Copyright Emmanuel Mongin
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Protein_Adaptor - DESCRIPTION of Object

=head1 SYNOPSIS
use Bio::EnsEMBL::DBSQL::Obj;
use Bio::EnsEMBL::DBSQL::Protein_Adaptor;

$db = new Bio::EnsEMBL::DBSQL::Obj( -user => 'root', -db => 'pog' , -host => 'caldy' , -driver => 'mysql' );
my $protein_adaptor=Bio::EnsEMBL::Protein_Adaptor->new($obj);

my $protein = $protein_adaptor->fetch_Protein_by_dbid;



=head1 DESCRIPTION

This Object inherit from BaseAdaptor following the new adaptor rules. It also has pointers to 3 different objects: Obj.pm, Gene_Obj.pm and FamilyAdaptor.pm (which is not currently used). This pointers allow the object to use the methods contained in these objects. SNPs db adaptor may also be added in these pointers.
The main method may be fetch_Protein_by_dbid, which return a complete protein object. Different methods are going to be develloped in this object to allow complexe queries at the protein level in Ensembl.

=head1 CONTACT

mongin@ebi.ac.uk

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::EnsEMBL::DBSQL::Protein_Adaptor;
use vars qw(@ISA);
use strict;


use Bio::EnsEMBL::DBSQL::BaseAdaptor;
use Bio::EnsEMBL::DBSQL::DBAdaptor;

use Bio::EnsEMBL::Protein;



use Bio::EnsEMBL::DBSQL::Protein_Feature_Adaptor;
use Bio::Species;
use Bio::EnsEMBL::DBSQL::DBEntryAdaptor;
use Bio::EnsEMBL::Utils::Eprof qw(eprof_start eprof_end);

# this is required at the right point if needed
#use Bio::EnsEMBL::ExternalData::GeneSNP;

#use Bio::EnsEMBL::ExternalData::Family::FamilyAdaptor;

@ISA = qw(Bio::EnsEMBL::DBSQL::BaseAdaptor);


=head2 fetch_Protein_by_transcriptId

 Title   : fetch_Protein_by_transcriptId
 Usage   :
 Function:
 Example :
 Returns : 
 Args    : transcript id (ENSTxxxx)

=cut

sub fetch_Protein_by_transcriptId{
   my ($self,$transid) = @_;
   my $query = "SELECT	t.translation_id 
		FROM    transcript as t, 
			transcript_stable_id as s 
		WHERE	s.stable_id = '$transid' 
		AND	t.transcript_id = s.transcript_id";
   my $sth = $self->prepare($query);
   $sth->execute();
   my @row = $sth->fetchrow;
   
   return $self->fetch_Protein_by_dbid($row[0]);
 }


=head2 fetch_Protein_by_translationId

 Title   : fetch_Protein_by_translationId
 Usage   :
 Function:
 Example :
 Returns : 
 Args    : protein id (ENSPxxxx)

=cut

sub fetch_Protein_by_translationId{
   my ($self,$transid) = @_;
   my $query = "SELECT	translation_id 
		FROM	translation_stable_id
		WHERE	stable_id = '$transid'";
   my $sth = $self->prepare($query);
   $sth->execute();
   my @row = $sth->fetchrow;
   return $self->fetch_Protein_by_dbid($row[0]);
 }


=head2 fetch_Protein_by_dbid

 Title   : fetch_Protein_by_dbid
 Usage   :$obj->fetch_Protein_by_dbid($id)
 Function:Built a whole Protein object for a given protein id
 Example :
 Returns : Protein Object
 Args    :Protein internal id (e.g. 256674)


=cut

sub fetch_Protein_by_dbid{
   my ($self,$id) = @_;


   #Get the transcript id from the translation id 
   my $query = "SELECT	t.transcript_id, 
			g.stable_id, 
			s.stable_id 
		FROM	transcript as t, 
			gene_stable_id as g,
			translation_stable_id as s 
		WHERE	t.translation_id = '$id' 
		AND	t.translation_id = s.translation_id
		AND	g.gene_id = t.gene_id
		";

   my $sth = $self->prepare($query);
   $sth ->execute();
   my @rowid = $sth->fetchrow;

   my $transid = $rowid[0];
   my $geneid = $rowid[1];
   my $stableid = $rowid[2];

   if (!defined $transid) {
       $self->throw("$id does not have a transcript id");
   }

   if (!defined $geneid) {
       $self->throw("$id does not have a gene id");
   }

#Get the transcript object (this will allow us to get the aa sequence of the protein
   my $transcript = $self->fetch_Transcript_by_dbid($transid);

   
#Get all of the family (at the Transcript level), not implemented yet
   #my $family = $self->fetch_Family_by_dbid($id);

#Get all SNPs ?????? method which would be nice to implement


#Get the aa sequence out of the transcript object   
   #my $sequence = $transcript->translate->seq;
   my $sequence = $transcript->translate->seq;

#Calculate the length of the Peptide   
   my $length = length($sequence);
   if ($length == 0) {
       $self->throw("Transcript".$transcript->id." does not have any amino acid sequence"); 
       #return 0;
   }
  
#Define the moltype
   my $moltype = "protein";
   
   my $meta_obj = $self->db->get_MetaContainer();
   my $species = $meta_obj->get_Species();
   
   #This has to be changed, the description may be take from the protein family description line
   my $desc = "Protein predicted by Ensembl";
  
#Create the Protein object
   my $protein = Bio::EnsEMBL::Protein->new ( -seq =>$sequence,
					      -accession_number  => $id,
					      -display_id => $id,
					      -primary_id => $id,
					      -id => $id,
					      -desc => $desc,
					      );

   #Set up the adaptor handler for the protein object
   $protein->db($self->db);

   #Add the species object to protein object
   $protein->species($species);

   $protein->transcriptac($transid);
   $protein->geneac($geneid);
   $protein->stable_id($stableid);
   

#Add the date of creation of the protein to the annotation object
   my $ann  = Bio::Annotation->new;
      
   $protein ->annotation($ann);
   #$protein->add_date($created);
   #$protein->add_date($modified);

   return $protein;
}


=head2 fetch_Protein_ligth

 Title   : fetch_Protein_ligth
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub fetch_Protein_ligth{
my ($self,$id) = @_;


   #Get the transcript id from the translation id 
   my $query = "SELECT	t.transcript_id 
		FROM	transcript as t 
		WHERE	t.translation_id = '$id' 
		";

   my $sth = $self->prepare($query);
   $sth ->execute();
   my @rowid = $sth->fetchrow;

   my $transid = $rowid[0];

   if (!defined $transid) {
       $self->throw("$id does not have a transcript id");
   }


#Get the transcript object (this will allow us to get the aa sequence of the protein
   my $transcript = $self->fetch_Transcript_by_dbid($transid);


#Get the aa sequence out of the transcript object   
   my $sequence = $transcript->translate->seq;

#Calculate the length of the Peptide   
   my $length = length($sequence);
   if ($length == 0) {
       $self->throw("Transcript".$transcript->id." does not have any amino acid sequence"); 
       #return 0;
   }
  
#Define the moltype
   my $moltype = "protein";
   
   
   #This has to be changed, the description may be take from the protein family description line
   my $desc = "Protein predicted by Ensembl";
  
#Create the Protein object
   my $protein = Bio::EnsEMBL::Protein->new ( -seq =>$sequence,
					      -accession_number  => $id,
					      -display_id => $id,
					      -primary_id => $id,
					      -id => $id,
					      -desc => $desc,
					      );

   return $protein;

}


=head2 fetch_Transcript_by_dbid

 Title   : fetch_Transcript_by_dbid
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub fetch_Transcript_by_dbid{
   my ($self,$transcript_id) = @_;

#Call the method get_Transcript on Gene_Obj.om   
   my $transcript = $self->db->get_TranscriptAdaptor->fetch_by_dbID($transcript_id);
         
   return $transcript;

}

=head2 fetch_DBlinks_by_dbid

 Title   : fetch_DBlinks
 Usage   :$prot_adaptor->fetch_DBlinks_by_dbid($protein_id)
 Function:Get all of the DBlinks for one protein given a protein object and attach them to the object
 Example :
 Returns :an array of dblinks
 Args    :Protein id


=cut



sub fetch_DBlinks_by_dbid {
    my($self,$protein_id) = @_;
    my @links;

    my $query = "select dbl.external_db,dbl.external_id from transcriptdblink as dbl, transcript as t where dbl.transcript_id = t.id and t.translation = '$protein_id'";
    my $sth = $self->prepare($query);
    $sth ->execute();
    while( (my $hash = $sth->fetchrow_hashref()) ) {
	
	my $dblink = Bio::Annotation::DBLink->new();
	$dblink->database($hash->{'external_db'});
	$dblink->primary_id($hash->{'external_id'});
	

	push(@links,$dblink);
    }
    return @links;
}


=head2 fetch_Protein_features_by_dbid

 Title   : fetch_Protein_features_by_dbid
 Usage   :$prot_adaptor->fetch_Protein_features_by_dbid($protein_id)
 Function:Get all of the protein features for a given protein object and attach it to the object
 Example :
 Returns :nothing
 Args    :Protein Object


=cut

sub fetch_Protein_features_by_dbid{
   my ($self,$protein_id) = @_;
     
#This call a method contained in Protein_Feature_Adaptor, returns feature objects for the given protein
   my @features = $self->_protfeat_obj->fetch_by_translationID($protein_id);

   return @features;

}


=head2 fetch_by_feature

 Title   : fetch_by_feature
 Usage   :my @proteins = $obj->fetch_by_feature($feature_id)
 Function:This method should be in theory in the Protein_Feature_Adaptor object but has been placed here for convenience (the Protein_Feature_Adaptor object may be transfered to this Protein_Adaptor object...to be discussed). The function of this method is to retrieve all of the proteins which have a given feature (retrieved by feature id)
 Example :
 Returns : An Array of protein objects
 Args    : feature id (hid in the protein_feature table)


=cut

sub fetch_by_feature{
   my ($self,$feature) = @_;
   my @proteins;
   
   my $query = "select translation from protein_feature where hid = '$feature'";
   my $sth = $self->prepare($query);
   $sth ->execute();
   while( (my $pepid = $sth->fetchrow) ) {
       my $pep = $self->fetch_Protein_by_dbid($pepid);
       push(@proteins,$pep);
   }
   return @proteins;
}

=head2 fetch_by_array_feature

 Title   : fetch_by_array_feature
 Usage   :my @proteins = $obj->fetch_by_array_feature(@domaines)
 Function:This method allow to query proteins matching different domains, this will only return the protein which have the domain queried
 Example :
 Returns : An array of protein objects
 Args    :Interpro signatures


=cut

sub fetch_by_array_feature{
   my ($self,@feature) = @_;

   my $nb = scalar @feature;
   
   my %seen;
   my @result;

   if (@feature) {
       foreach my $dbl(@feature) {


	   my @protein_linked = $self->fetch_by_feature($dbl);
	   foreach my $prot (@protein_linked) {
	       if ($seen{$prot}) {
		   my $count = $seen{$prot};
		   $count = $count++;
		   $seen{$prot} = $count;
	       }
	       else {
		   $seen{$prot} = 1;
	       }
	   }
       }
   }
   foreach my $key (keys (%seen)) {
       if ($seen{$key} == $nb) {
	   push (@result, $key);
       }
   }
   
   return @result;
   
}

=head2 get_Introns

 Title   : get_Introns
 Usage   : $protein_adaptor->get_Introns($proteinid)
 Function: Return an array of protein features introns
 Example :
 Returns : 
 Args    : Protein ac


=cut

sub get_Introns{
    my ($self,$protid) = @_;
    my @array_features;
    my $previous_ex_end=0;
    my $count = 1;

    my $query = "select transcript_id from transcript where translation_id = '$protid'";
    my $sth = $self->prepare($query);
    $sth ->execute();
    my @rowid = $sth->fetchrow;
    my $transid = $rowid[0];
    
    if (!defined $transid) {
	$self->throw("No transcript can be retrieved with this translation id: $protid")
	}
    
    my $transcript = $self->fetch_Transcript_by_dbid($transid);
    my ($starts,$ends) = $transcript->pep_coords;
    
    my @exons = $transcript->get_all_Exons();
    my $nbex = scalar(@exons);
    
    foreach my $ex(@exons) {
	my $length;
	my $exid = $ex->dbID();
	my ($ex_start, $ex_end) = $self->get_exon_global_coordinates($exid);
	if ($previous_ex_end != 0) {
	    my $intron_start = $previous_ex_end;
	    my $intron_end = $ex_start;

#Create an analysis object
	    my $anal = Bio::EnsEMBL::FeatureFactory->new_analysis();
	
	    $anal->program        ('NULL');
	    $anal->program_version('NULL');
	    $anal->gff_source     ('Intron');
	    $anal->gff_feature    ('Intron');
	    #$anal->dbID(2);


	    my $feat1 = new Bio::EnsEMBL::SeqFeature ( -seqname => $protid,
						       -start => $starts->[$count],
						       -end => $starts->[$count],
						       -score => 0, 
						       -percent_id => "NULL",
						       -analysis => $anal,
						       -p_value => "NULL");
	    
	    my $feat2 = new Bio::EnsEMBL::SeqFeature (-start => $intron_start,
						      -end => $intron_end,
						      -analysis => $anal,
						      -seqname => "Intron");
	    
	    my $feature = new Bio::EnsEMBL::Protein_FeaturePair(-feature1 => $feat1,
								-feature2 => $feat2,);
	    
	    push(@array_features,$feature);
	    
	    $count++;
	}
	$previous_ex_end = $ex_end;
	
    }
     return @array_features; 
}



=head2 get_exon_global_coordinates

 Title   : get_exon_global_coordinates
 Usage   : $protein_adaptor->get_exon_global_coordinates($exon_id)
 Function: Get the start and end position of the exon in globale coordinates
 Example :
 Returns : Start and end of the exon
 Args    : Exon id


=cut

sub get_exon_global_coordinates{
   my ($self,$exid) = @_;

#This sql satement calculate the start and end of the exon in global coordinates
   my $query ="SELECT
               IF(sgp.raw_ori=1,(e.seq_start+sgp.chr_start-sgp.raw_start),
                 (sgp.chr_start+sgp.raw_end-e.seq_end)) as start,
               IF(sgp.raw_ori=1,(e.seq_end+sgp.chr_start-sgp.raw_start),
                 (sgp.chr_start+sgp.raw_end-e.seq_start)) as end
               FROM       static_golden_path as sgp ,exon as e
               WHERE      sgp.raw_id=e.contig_id
               AND        e.exon_id='$exid'";
              

   my $sth = $self->prepare($query);
   $sth->execute;
  
   my @row = $sth->fetchrow;

   

   my $start = $row[0];
   my $end = $row[1];

   return ($start,$end);
}


=head2 get_snps

 Title   : get_snps
 Usage   : $protein_adaptor->get_snps($protein)
 Function:Get all of the snps for a peptide (for now return them in the format of a Protein_FeatureObject)
 Example :
 Returns :An array of Protein_FeaturePair object containing the snps  
 Args    :protein object


=cut
    
sub get_snps {
    my ($self,$protein,$sndb,$gbd) = @_;

    
    my $transid = $protein->transcriptac();

    my @exons;
    my @snps;
    my $count = 0;
    my $ex;
    my $snp;
    my %expos;
    my @array_snp;
    my @features;

    #Get the exon information for this given transcript
    my $sth = $gbd->prepare("select exon,exon_chrom_start,exon_chrom_end from exon where transcript='$transid'");
    $sth->execute;
    
    while (my @loc = $sth->fetchrow) {
	my $loc;
	$count++;
	$expos{$loc[0]} = $count;
	
	$$loc[0]->{id} = $loc[0];
	$$loc[0]->{"pos"} = $count;
	$$loc[0]->{start} = $loc[1];
	$$loc[0]->{end} = $loc[2];
	$$loc[0]->{"length"} = ($loc[2] - $loc[1]);
	push (@exons,$$loc[0]);
    }
	
    #Now, get information about the snps on this transcript    
    my $sth1 = $gbd->prepare("select exon,s.refsnpid,s.snp_chrom_start from exon e, gene_snp s where s.gene=e.gene and s.snp_chrom_start>e.exon_chrom_start and s.snp_chrom_start<e.exon_chrom_end and e.transcript='$transid'");
    $sth1->execute;
  
    while (@array_snp = $sth1->fetchrow) {
	my $array_snp;
	$$array_snp[1]->{exon} = $array_snp[0];
	$$array_snp[1]->{id} = $array_snp[1];
	$$array_snp[1]->{"pos"} = $array_snp[2];
	push (@snps,$$array_snp[1]);
    }
    
    foreach my $s(@snps) {
	my $e;
	my $exid = $s->{exon};
	
	my $pos = $expos{$exid};
	
	my $previous_exons_length = 0;

	foreach my $exs(@exons) {
	    if ($exs->{"pos"} < $pos) {
		$previous_exons_length += $exs->{"length"};
	    }
	    if ($exs->{"pos"} == $pos) {
		$e = $exs;
	    }
	}
	#Get the location of the snp in aa coordinates      
        my $aa_pos = int (($s->{"pos"} - $e->{start} + $previous_exons_length)/3) + 1;
	
	my $anal = Bio::EnsEMBL::FeatureFactory->new_analysis();
	
	    $anal->program        ('NULL');
	    $anal->program_version('NULL');
	    $anal->gff_source     ('SNP');
	    $anal->gff_feature    ('SNP');
	    #$anal->dbID(2);


	    my $feat1 = new Bio::EnsEMBL::SeqFeature ( -seqname => $protein->id,
						       -start => $aa_pos,
						       -end => $aa_pos,
						       -score => 0, 
						       -percent_id => "NULL",
						       -analysis => $anal,
						       -p_value => "NULL");
	    
	    my $feat2 = new Bio::EnsEMBL::SeqFeature (-start => 0,
						      -end => 0,
						      -analysis => $anal,
						      -seqname => "Variant");
	    
	    my $feature = new Bio::EnsEMBL::Protein_FeaturePair(-feature1 => $feat1,
								-feature2 => $feat2,);
	push(@features,$feature);
	
    }
    return @features;
}

