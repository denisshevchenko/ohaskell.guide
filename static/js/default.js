$(document).ready(function(){
    $('.button-collapse').sideNav({
            menuWidth: 290, // Default is 240
            edge: 'left', // Choose the horizontal origin
            closeOnClick: true // Closes side-nav on <a> clicks, useful for Angular/Meteor
        }
    );

    $('.show-comments').on('click', function(){
          var disqus_shortname = 'ohaskell'; // Replace this value with *your* username.

          // ajax request to load the disqus javascript
          $.ajax({
                  type: "GET",
                  url: "//" + disqus_shortname + ".disqus.com/embed.js",
                  dataType: "script",
                  cache: true
          });
    });
})
