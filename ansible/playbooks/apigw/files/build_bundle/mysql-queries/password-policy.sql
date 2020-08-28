update password_policy set properties = '<?xml version="1.0" encoding="UTF-8"?>
<java version="1.8.0_73" class="java.beans.XMLDecoder">
 <object class="java.util.TreeMap">
  <void method="put">
   <string>allowableChangesPerDay</string>
   <boolean>true</boolean>
  </void>
  <void method="put">
   <string>charDiffMinimum</string>
   <int>4</int>
  </void>
  <void method="put">
   <string>forcePasswordChangeNewUser</string>
   <boolean>false</boolean>
  </void>
  <void method="put">
   <string>lowerMinimum</string>
   <int>1</int>
  </void>
  <void method="put">
   <string>maxPasswordLength</string>
   <int>32</int>
  </void>
  <void method="put">
   <string>minPasswordLength</string>
   <int>8</int>
  </void>
  <void method="put">
   <string>noRepeatingCharacters</string>
   <boolean>true</boolean>
  </void>
  <void method="put">
   <string>numberMinimum</string>
   <int>1</int>
  </void>
  <void method="put">
   <string>repeatFrequency</string>
   <int>10</int>
  </void>
  <void method="put">
   <string>symbolMinimum</string>
   <int>1</int>
  </void>
  <void method="put">
   <string>upperMinimum</string>
   <int>1</int>
  </void>
 </object>
</java>
';

update internal_user set password_expiry = -1;

