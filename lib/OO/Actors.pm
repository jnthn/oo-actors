role Actor {
    has Lock::Async $!orderer .= new;

    method !post($method, $capture) {
        $!orderer.lock.then({
            LEAVE $!orderer.unlock;
            $method(self, |$capture)
        });
    }
}

class MetamodelX::ActorHOW is Metamodel::ClassHOW {
    my %bypass = :new, :bless, :BUILDALL, :BUILD, 'dispatch:<!>' => True;
    
    method find_method(Mu \obj, $name, |) {
        my $method = callsame;
        my $post = self.find_private_method(obj, 'post');
        %bypass{$name} || !$method
            ?? $method
            !!  -> \obj, |capture { $post(obj, $method, capture); }
    }
    
    method compose(Mu \type) {
        self.add_role(type, Actor);
        self.Metamodel::ClassHOW::compose(type);
    }
    
    method publish_method_cache(|) { }
}

my package EXPORTHOW {
    package DECLARE {
        constant actor = MetamodelX::ActorHOW;
    }
}
