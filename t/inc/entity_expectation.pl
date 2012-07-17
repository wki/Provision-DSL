sub test_expectation {
    my ($e, $testcase, $modifier) = @_;
    
    my $expect = $modifier ? "expect_$modifier" : 'expect';
    
    foreach my $key (sort keys(%{$testcase->{$expect}})) {
        if ($testcase->{$expect}->{$key} =~ m{\A [01] \z}xms) {
            if ($testcase->{$expect}->{$key}) {
                ok $e->$key(),
                   "$testcase->{name} $modifier: $key is TRUE";
            } else {
                ok !$e->$key(),
                   "$testcase->{name} $modifier: $key is FALSE";
            }
        } elsif (ref $testcase->{$expect}->{$key}) {
            my $expectation =
                ref $testcase->{$expect}->{$key} eq 'ARRAY'
                    ? join(', ', @{$testcase->{$expect}->{$key}})
                : $testcase->{$expect}->{$key};
            is_deeply $e->$key(), $testcase->{$expect}->{$key},
                      "$testcase->{name} $modifier: $key is '$expectation'";
        } else {
            is $e->$key(), $testcase->{$expect}->{$key},
               "$testcase->{name} $modifier: $key is $testcase->{$expect}->{$key}";
        }
    }
}
