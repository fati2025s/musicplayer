class FilterByArtist extends Filter {
    private String[] artist;
    public FilterByArtist(String... artist) {
        this.artist = artist;
    }
    public boolean accept(Song music) {
        for(int i=0;i<artist.length;i++){
            if(artist[i].equals(music.getArtist())){
                return true;
            }
        }
        return false;
    }
}
/*باید فقط اسم یه خواننده رو بگیریم و فیلترش کنیم نه چندتا خواننده

    public FilterByArtist(String artist) {
        this.artist = artist;
    }

    @Override
    public boolean accept(Song song) {
        return artist.equalsIgnoreCase(song.getArtist());
    }
}*/
