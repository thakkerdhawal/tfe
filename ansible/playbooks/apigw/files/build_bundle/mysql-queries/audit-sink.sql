
update cluster_properties set propkey='audit.sink.policy.guid', propvalue=(select guid from policy where name = '[Internal Audit Sink Policy]') where propkey = 'audit.sink.policy.guix';

