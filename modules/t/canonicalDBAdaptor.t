use strict;
use warnings;

use lib 't';

BEGIN { $| = 1;
	use Test;
	plan tests => 44;
}


use TestUtils qw(debug test_getter_setter);
use MultiTestDB;
use Bio::EnsEMBL::DBSQL::DBAdaptor;
use Bio::EnsEMBL::DBSQL::BaseFeatureAdaptor;
use Bio::EnsEMBL::DBSQL::ProteinFeatureAdaptor;
use Bio::EnsEMBL::DBSQL::DnaAlignFeatureAdaptor;

# Get a DBAdaptor to from the test system
my $multi = MultiTestDB->new;
ok($multi);
my $db = $multi->get_DBAdaptor("core");
ok($db);

# Should get meaningful type back
my $test_adaptor;

$test_adaptor = $db->get_ArchiveStableIdAdaptor();
ok($test_adaptor->isa("Bio::EnsEMBL::DBSQL::ArchiveStableIdAdaptor"));
$test_adaptor = $db->get_QtlFeatureAdaptor();
ok($test_adaptor->isa("Bio::EnsEMBL::Map::DBSQL::QtlFeatureAdaptor"));
$test_adaptor = $db->get_QtlAdaptor();
ok($test_adaptor->isa("Bio::EnsEMBL::Map::DBSQL::QtlAdaptor"));
$test_adaptor = $db->get_ProteinFeatureAdaptor();
ok($test_adaptor->isa("Bio::EnsEMBL::DBSQL::ProteinFeatureAdaptor"));
$test_adaptor = $db->get_ProteinAdaptor();
ok($test_adaptor->isa("Bio::EnsEMBL::DBSQL::ProteinAdaptor"));
$test_adaptor = $db->get_MapFragAdaptor();
ok($test_adaptor->isa("Bio::EnsEMBL::DBSQL::MapFragAdaptor"));
$test_adaptor = $db->get_CloneAdaptor();
ok($test_adaptor->isa("Bio::EnsEMBL::DBSQL::CloneAdaptor"));
$test_adaptor = $db->get_PredictionTranscriptAdaptor();
ok($test_adaptor->isa("Bio::EnsEMBL::DBSQL::PredictionTranscriptAdaptor"));
$test_adaptor = $db->get_SequenceAdaptor();
ok($test_adaptor->isa("Bio::EnsEMBL::DBSQL::SequenceAdaptor"));
$test_adaptor = $db->get_GeneAdaptor();
ok($test_adaptor->isa("Bio::EnsEMBL::DBSQL::ProxyGeneAdaptor"));
$test_adaptor = $db->get_ExonAdaptor();
ok($test_adaptor->isa("Bio::EnsEMBL::DBSQL::ExonAdaptor"));
$test_adaptor = $db->get_TranscriptAdaptor();
ok($test_adaptor->isa("Bio::EnsEMBL::DBSQL::TranscriptAdaptor"));
$test_adaptor = $db->get_TranslationAdaptor();
ok($test_adaptor->isa("Bio::EnsEMBL::DBSQL::TranslationAdaptor"));
$test_adaptor = $db->get_RawContigAdaptor();
ok($test_adaptor->isa("Bio::EnsEMBL::DBSQL::RawContigAdaptor"));
$test_adaptor = $db->get_SliceAdaptor();
ok($test_adaptor->isa("Bio::EnsEMBL::DBSQL::SliceAdaptor"));
$test_adaptor = $db->get_AnalysisAdaptor();
ok($test_adaptor->isa("Bio::EnsEMBL::DBSQL::AnalysisAdaptor"));
$test_adaptor = $db->get_SimpleFeatureAdaptor();
ok($test_adaptor->isa("Bio::EnsEMBL::DBSQL::SimpleFeatureAdaptor"));
$test_adaptor = $db->get_RepeatConsensusAdaptor();
ok($test_adaptor->isa("Bio::EnsEMBL::DBSQL::RepeatConsensusAdaptor"));
$test_adaptor = $db->get_RepeatFeatureAdaptor();
ok($test_adaptor->isa("Bio::EnsEMBL::DBSQL::ProxyRepeatFeatureAdaptor"));
$test_adaptor = $db->get_ProteinAlignFeatureAdaptor();
ok($test_adaptor->isa("Bio::EnsEMBL::DBSQL::ProteinAlignFeatureAdaptor"));
$test_adaptor = $db->get_DnaAlignFeatureAdaptor();
ok($test_adaptor->isa("Bio::EnsEMBL::DBSQL::ProxyDnaAlignFeatureAdaptor"));
$test_adaptor = $db->get_AssemblyMapperAdaptor();
ok($test_adaptor->isa("Bio::EnsEMBL::DBSQL::AssemblyMapperAdaptor"));
$test_adaptor = $db->get_DBEntryAdaptor();
ok($test_adaptor->isa("Bio::EnsEMBL::DBSQL::DBEntryAdaptor"));
$test_adaptor = $db->get_KaryotypeBandAdaptor();
ok($test_adaptor->isa("Bio::EnsEMBL::DBSQL::KaryotypeBandAdaptor"));
$test_adaptor = $db->get_ChromosomeAdaptor();
ok($test_adaptor->isa("Bio::EnsEMBL::DBSQL::ChromosomeAdaptor"));
$test_adaptor = $db->get_SupportingFeatureAdaptor();
ok($test_adaptor->isa("Bio::EnsEMBL::DBSQL::SupportingFeatureAdaptor"));
$test_adaptor = $db->get_MarkerFeatureAdaptor();
ok($test_adaptor->isa("Bio::EnsEMBL::Map::DBSQL::MarkerFeatureAdaptor"));
$test_adaptor = $db->get_MarkerAdaptor();
ok($test_adaptor->isa("Bio::EnsEMBL::Map::DBSQL::MarkerAdaptor"));

# Note get_BlastAdaptor() and get_SNPAdaptor() require DBs of type
# 'blast' and 'lite' respectively - these are not available via MultiTestDB
#my $blast_db = $multi->get_DBAdaptor("lite");
#ok($blast_db);
#$test_adaptor = $blast_db->get_BlastAdaptor();
#ok($test_adaptor->isa("Bio::EnsEMBL::External::BlastAdaptor"));
#$test_adaptor = $db->get_SNPAdaptor();
#ok($test_adaptor->isa("Bio::EnsEMBL::DBSQL::ProxySNPAdaptor"));

# Should get an error if we ask for something non-existent
eval { $db->get_adaptor("SomeNonExistentType") };
ok($@);

# Check setting module with good values
ok($db->set_adaptor("ArchiveStableId", "Bio::EnsEMBL::DBSQL::ArchiveStableIdAdaptor" ));

# Setting an unknown data type should give an error
eval { $db->set_adaptor("SomeNonExistentType", "Bio::EnsEMBL::DBSQL::ArchiveStableIdAdaptor") };
ok($@);

# Setting to a non-subclass of the default should give an error
eval { $db->set_adaptor("ArchiveStableId", "Bio::EnsEMBL::DBSQL::GeneAdaptor") };
ok($@);

# Generic adaptors

# Should work OK with subclasses of BaseFeatureAdaptor
my $rfa = Bio::EnsEMBL::DBSQL::RepeatFeatureAdaptor->new($db);
my $sfa = Bio::EnsEMBL::DBSQL::SimpleFeatureAdaptor->new($db);
ok($db->add_GenericFeatureAdaptor("Repeat", $rfa));
ok($db->add_GenericFeatureAdaptor("Simple", $sfa));


# Check get-ing the above
# by name ...
my %generic_adaptors = $db->get_GenericFeatureAdaptors("Simple", "Repeat");
ok(%generic_adaptors);
ok(exists(%generic_adaptors->{'Simple'}));

# no arg should return all
%generic_adaptors = $db->get_GenericFeatureAdaptors();
my $size = keys(%generic_adaptors);
ok($size == 2);
ok(%generic_adaptors->{"Simple"});
ok(%generic_adaptors->{"Repeat"});

# requesting one that hasn't been added should throw
eval { my %generic_adpators = $db->get_GenericFeatureAdaptors("Mickey") };
ok($@);

# Slice tests - should these go in slice.t?
my $slice = $db->get_SliceAdaptor()->fetch_by_chr_start_end('X', 1, 10000);
ok($slice);

my %features = $slice->get_generic_features();
ok(%features);
