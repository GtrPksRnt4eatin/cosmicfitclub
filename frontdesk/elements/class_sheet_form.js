function ClassSheetForm() {

}

ClassSheetForm.prototype = {
  constructor: ClassSheetForm,

}

Object.assign( ClassSheetForm.prototype, element );
Object.assign( ClassSheetForm.prototype, ev_channel );

ClassSheetForm.prototype.HTML = ES5Template(function(){ /**
  <div class='class_sheet_form'>
    <div class='form_title'> Edit Class Sheet </div>
    <div class='tuple'>
      <div class='label'>Start Time:</div>
      <div class='value'></div>
    </div>
    <div class='tuple'>
      <div class='label'>Class:</div>
      <div class='value'></div>
    </div>
    <div class='tuple'>
      <div class='label'>Teacher:</div>
      <div class='value'></div>
    </div>
  </div>
**/}).untab(2);

ClassSheetForm.prototype.CSS = ES5Template(function(){ /**

**/}).untab(2);