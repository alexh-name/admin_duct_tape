var new_msg = '';
var msgs = '';
var msgs_term = '';
var mmb64 = '';
var from = '';
var to = '';
var subject = '';
var body = '';
var mm_counter = 0;

// Get contents of form
function compose() {
  var date = new Date();
  new_msg = 
    "\f"+"Reply-To: <crew-post@jugendrettet.org>"+"\n"
    +"Date: "+date+"\n"
    +"From: "+$("#from").val()+"\n"
    +"To: "+$("#to").val()+"\n"
    +"Subject: "+$("#subject").val()+"\n"
    +"\n"+$("#body").val()+"\n";
}

// Collect all messages to one variable
function add() {
  msgs = msgs + new_msg;
  mm_counter ++;
  document.getElementById("mm-counter").innerHTML = 'Multimail (' + mm_counter + '):';
}

// Add another form feed to the end
function terminate() {
  msgs_term = msgs+"\f"
}

// After one message completed, clear the form
function flush() {
  document.getElementById("from").value = '';
  document.getElementById("to").value = '';
  document.getElementById("subject").value = '';
  document.getElementById("body").value = '';
  document.getElementById("mmarea").value = '';
  document.getElementById("error").style.display = 'none';
}

// Encode all collected messages to base64
// and show it
function b64() {
  mmb64 = btoa(msgs_term);
  document.getElementById("mmarea").value = mmb64;
}

// Trigger productive functions if everythings ok
function show() {
  compose();
  add();
  flush();
  terminate();
  b64();
}

// Check whether form is filled
function trigger() {
  from = $("#from").val();
  to = $("#to").val();
  subject = $("#subject").val();
  body = $("#body").val();
  if (from != '' && to != '' && subject != '' && body != '') {
    show();
  }
  else {
    document.getElementById("error").style.display = 'initial';
  };
}

// Copy multimail to clipboard
var copyTextareaBtn = document.querySelector('.js-textareacopybtn');

copyTextareaBtn.addEventListener('click', function(event) {
  var copyTextarea = document.querySelector('.js-copytextarea');
  copyTextarea.select();

  try {
    var successful = document.execCommand('copy');
    var msg = successful ? 'successful' : 'unsuccessful';
    console.log('Copying text command was ' + msg);
  } catch (err) {
    console.log('Oops, unable to copy');
  }
});