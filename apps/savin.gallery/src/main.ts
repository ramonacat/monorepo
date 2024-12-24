import "./style.css";

document.addEventListener('DOMContentLoaded', function(){ 

   for(const item of document.querySelectorAll('.gallery li'))
   {
       item.querySelector('img').addEventListener('click', function(){
            item.querySelector('dialog').showModal();
       });
   }

   for(const dialog of document.querySelectorAll('dialog')) {
        dialog.addEventListener('click', () => dialog.close());
   }
});
